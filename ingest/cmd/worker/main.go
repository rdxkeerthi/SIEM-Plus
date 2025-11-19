package main

import (
    "bytes"
    "context"
    "database/sql"
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "strings"
    "time"

    _ "github.com/lib/pq"
    "github.com/segmentio/kafka-go"
)

type Config struct {
    KafkaBrokers        []string
    EventsTopic         string
    AlertsTopic         string
    EventsConsumerGroup string
    AlertsConsumerGroup string
    PostgresURL         string
    OpenSearchURL       string
}

func loadConfig() Config {
    return Config{
        KafkaBrokers:        strings.Split(getEnv("KAFKA_BROKERS", "localhost:9092"), ","),
        EventsTopic:         getEnv("EVENTS_TOPIC", "events"),
        AlertsTopic:         getEnv("ALERTS_TOPIC", "alerts"),
        EventsConsumerGroup: getEnv("EVENTS_CONSUMER_GROUP", "siem-events-indexer"),
        AlertsConsumerGroup: getEnv("ALERTS_CONSUMER_GROUP", "siem-alerts-writer"),
        PostgresURL:         getEnv("POSTGRES_URL", "postgres://siem_admin:siem_password@localhost:5432/siem_plus?sslmode=disable"),
        OpenSearchURL:       strings.TrimSuffix(getEnv("OPENSEARCH_URL", "http://localhost:9200"), "/"),
    }
}

func getEnv(key, def string) string {
    if val := os.Getenv(key); val != "" {
        return val
    }
    return def
}

func main() {
    cfg := loadConfig()

    db, err := sql.Open("postgres", cfg.PostgresURL)
    if err != nil {
        log.Fatalf("failed to connect to Postgres: %v", err)
    }
    defer db.Close()

    httpClient := &http.Client{Timeout: 10 * time.Second}
    ctx := context.Background()

    go runEventIndexer(ctx, cfg, httpClient)

    if err := runAlertWriter(ctx, cfg, db); err != nil {
        log.Fatalf("alert writer exited: %v", err)
    }
}

func runEventIndexer(ctx context.Context, cfg Config, httpClient *http.Client) {
    reader := kafka.NewReader(kafka.ReaderConfig{
        Brokers: cfg.KafkaBrokers,
        GroupID: cfg.EventsConsumerGroup,
        Topic:   cfg.EventsTopic,
        MinBytes: 1,
        MaxBytes: 10e6,
    })
    defer reader.Close()

    log.Printf("event indexer consuming topic=%s", cfg.EventsTopic)

    for {
        msg, err := reader.ReadMessage(ctx)
        if err != nil {
            log.Printf("event reader error: %v", err)
            time.Sleep(2 * time.Second)
            continue
        }

        if err := indexEvent(httpClient, cfg.OpenSearchURL, msg.Value); err != nil {
            log.Printf("failed to index event offset=%d: %v", msg.Offset, err)
        }
    }
}

func indexEvent(client *http.Client, baseURL string, payload []byte) error {
    req, err := http.NewRequest(http.MethodPost, fmt.Sprintf("%s/events/_doc", baseURL), bytes.NewReader(payload))
    if err != nil {
        return err
    }
    req.Header.Set("Content-Type", "application/json")

    resp, err := client.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()

    if resp.StatusCode >= 300 {
        return fmt.Errorf("opensearch responded with %s", resp.Status)
    }
    return nil
}

func runAlertWriter(ctx context.Context, cfg Config, db *sql.DB) error {
    reader := kafka.NewReader(kafka.ReaderConfig{
        Brokers: cfg.KafkaBrokers,
        GroupID: cfg.AlertsConsumerGroup,
        Topic:   cfg.AlertsTopic,
        MinBytes: 1,
        MaxBytes: 10e6,
    })
    defer reader.Close()

    log.Printf("alert writer consuming topic=%s", cfg.AlertsTopic)

    for {
        msg, err := reader.ReadMessage(ctx)
        if err != nil {
            return err
        }

        if err := persistAlert(ctx, db, msg.Value); err != nil {
            log.Printf("failed to persist alert offset=%d: %v", msg.Offset, err)
        }
    }
}

func persistAlert(ctx context.Context, db *sql.DB, payload []byte) error {
    var alert map[string]interface{}
    if err := json.Unmarshal(payload, &alert); err != nil {
        return fmt.Errorf("parse alert: %w", err)
    }

    id := asString(alert["id"], fmt.Sprintf("alert-%d", time.Now().UnixNano()))
    tenantID := asString(alert["tenant_id"], "default")
    ruleID := asString(alert["rule_id"], "")
    severity := asString(alert["severity"], "medium")
    title := asString(alert["rule_name"], "Detection Alert")
    description := asString(alert["description"], "")

    _, err := db.ExecContext(
        ctx,
        `INSERT INTO alerts (id, tenant_id, rule_id, severity, status, title, description, event_data, created_at, updated_at)
         VALUES ($1, $2, NULLIF($3, ''), $4, 'open', $5, $6, $7::jsonb, NOW(), NOW())
         ON CONFLICT (id) DO UPDATE
         SET severity = EXCLUDED.severity,
             status = EXCLUDED.status,
             title = EXCLUDED.title,
             description = EXCLUDED.description,
             event_data = EXCLUDED.event_data,
             updated_at = NOW()`,
        id, tenantID, ruleID, severity, title, description, string(payload),
    )
    return err
}

func asString(value interface{}, fallback string) string {
    if value == nil {
        return fallback
    }
    switch v := value.(type) {
    case string:
        if v == "" {
            return fallback
        }
        return v
    case fmt.Stringer:
        return v.String()
    case float64:
        return fmt.Sprintf("%v", v)
    default:
        return fallback
    }
}
