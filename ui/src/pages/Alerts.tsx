import { useQuery } from '@tanstack/react-query'
import { BellIcon, ExclamationTriangleIcon } from '@heroicons/react/24/outline'
import axios from 'axios'
import { useAuthStore } from '../stores/authStore'

export default function Alerts() {
  const { token } = useAuthStore()

  const { data: alertsData } = useQuery({
    queryKey: ['alerts'],
    queryFn: async () => {
      const response = await axios.get('/api/v1/alerts', {
        headers: { Authorization: `Bearer ${token}` },
      })
      return response.data
    },
  })

  const alerts = alertsData?.alerts || []

  const getSeverityBadge = (severity: string) => {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return <span className="badge badge-danger">Critical</span>
      case 'high':
        return <span className="badge bg-orange-100 text-orange-800">High</span>
      case 'medium':
        return <span className="badge badge-warning">Medium</span>
      case 'low':
        return <span className="badge badge-info">Low</span>
      default:
        return <span className="badge bg-gray-100 text-gray-800">Unknown</span>
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status?.toLowerCase()) {
      case 'open':
        return <span className="badge bg-red-100 text-red-800">Open</span>
      case 'investigating':
        return <span className="badge bg-yellow-100 text-yellow-800">Investigating</span>
      case 'resolved':
        return <span className="badge badge-success">Resolved</span>
      case 'false_positive':
        return <span className="badge bg-gray-100 text-gray-800">False Positive</span>
      default:
        return <span className="badge bg-gray-100 text-gray-800">{status}</span>
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Alerts</h1>
          <p className="mt-2 text-gray-600">Security alerts and detections</p>
        </div>
        <div className="flex space-x-3">
          <select className="input">
            <option>All Severities</option>
            <option>Critical</option>
            <option>High</option>
            <option>Medium</option>
            <option>Low</option>
          </select>
          <select className="input">
            <option>All Status</option>
            <option>Open</option>
            <option>Investigating</option>
            <option>Resolved</option>
          </select>
        </div>
      </div>

      <div className="space-y-4">
        {alerts.length === 0 ? (
          <div className="card text-center py-12">
            <BellIcon className="w-12 h-12 mx-auto text-gray-400 mb-4" />
            <p className="text-gray-500">No alerts found</p>
            <p className="text-sm text-gray-400 mt-2">All systems are operating normally</p>
          </div>
        ) : (
          alerts.map((alert: any) => (
            <div key={alert.id} className="card hover:shadow-md transition-shadow cursor-pointer">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-2">
                    {alert.severity?.toLowerCase() === 'critical' && (
                      <ExclamationTriangleIcon className="w-5 h-5 text-red-500" />
                    )}
                    <h3 className="text-lg font-semibold text-gray-900">{alert.title}</h3>
                    {getSeverityBadge(alert.severity)}
                    {getStatusBadge(alert.status)}
                  </div>
                  
                  <p className="text-gray-600 mb-3">{alert.description}</p>
                  
                  <div className="flex items-center space-x-6 text-sm text-gray-500">
                    <span>Rule: {alert.rule_name || 'Unknown'}</span>
                    <span>•</span>
                    <span>Agent: {alert.hostname || 'N/A'}</span>
                    <span>•</span>
                    <span>{new Date(alert.created_at).toLocaleString()}</span>
                  </div>
                </div>
                
                <div className="ml-4 flex space-x-2">
                  <button className="btn btn-secondary text-sm">
                    Investigate
                  </button>
                  <button className="btn btn-primary text-sm">
                    Resolve
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
