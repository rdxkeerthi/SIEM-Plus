use anyhow::Result;
use std::fs::File;
use std::io::Read;
use std::path::Path;
use sha2::{Sha256, Digest};

pub fn hash_file(path: &Path, algorithm: &str) -> Result<String> {
    let mut file = File::open(path)?;
    let mut buffer = Vec::new();
    file.read_to_end(&mut buffer)?;

    let hash = match algorithm {
        "sha256" => {
            let mut hasher = Sha256::new();
            hasher.update(&buffer);
            format!("{:x}", hasher.finalize())
        }
        "blake3" => {
            let hash = blake3::hash(&buffer);
            hash.to_hex().to_string()
        }
        _ => {
            // Default to blake3
            let hash = blake3::hash(&buffer);
            hash.to_hex().to_string()
        }
    };

    Ok(hash)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use tempfile::NamedTempFile;

    #[test]
    fn test_hash_file_blake3() {
        let mut file = NamedTempFile::new().unwrap();
        file.write_all(b"test content").unwrap();
        
        let hash = hash_file(file.path(), "blake3").unwrap();
        assert!(!hash.is_empty());
        assert_eq!(hash.len(), 64); // blake3 produces 32-byte hash (64 hex chars)
    }

    #[test]
    fn test_hash_file_sha256() {
        let mut file = NamedTempFile::new().unwrap();
        file.write_all(b"test content").unwrap();
        
        let hash = hash_file(file.path(), "sha256").unwrap();
        assert!(!hash.is_empty());
        assert_eq!(hash.len(), 64); // sha256 produces 32-byte hash (64 hex chars)
    }
}
