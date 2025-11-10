import { useQuery } from '@tanstack/react-query'
import { FolderIcon } from '@heroicons/react/24/outline'
import axios from 'axios'
import { useAuthStore } from '../stores/authStore'

export default function Cases() {
  const { token } = useAuthStore()

  const { data: casesData } = useQuery({
    queryKey: ['cases'],
    queryFn: async () => {
      const response = await axios.get('/api/v1/cases', {
        headers: { Authorization: `Bearer ${token}` },
      })
      return response.data
    },
  })

  const cases = casesData?.cases || []

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Cases</h1>
          <p className="mt-2 text-gray-600">Incident investigation and case management</p>
        </div>
        <button className="btn btn-primary">
          <FolderIcon className="w-5 h-5 mr-2 inline" />
          Create Case
        </button>
      </div>

      <div className="grid grid-cols-1 gap-6">
        {cases.length === 0 ? (
          <div className="card text-center py-12">
            <FolderIcon className="w-12 h-12 mx-auto text-gray-400 mb-4" />
            <p className="text-gray-500">No cases found</p>
            <p className="text-sm text-gray-400 mt-2">Create a case to track security incidents</p>
          </div>
        ) : (
          cases.map((caseItem: any) => (
            <div key={caseItem.id} className="card hover:shadow-md transition-shadow cursor-pointer">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-2">
                    <h3 className="text-lg font-semibold text-gray-900">{caseItem.title}</h3>
                    {caseItem.severity === 'critical' && <span className="badge badge-danger">Critical</span>}
                    {caseItem.severity === 'high' && <span className="badge bg-orange-100 text-orange-800">High</span>}
                    {caseItem.severity === 'medium' && <span className="badge badge-warning">Medium</span>}
                    {caseItem.severity === 'low' && <span className="badge badge-info">Low</span>}
                    
                    {caseItem.status === 'open' && <span className="badge bg-red-100 text-red-800">Open</span>}
                    {caseItem.status === 'investigating' && <span className="badge bg-yellow-100 text-yellow-800">Investigating</span>}
                    {caseItem.status === 'closed' && <span className="badge badge-success">Closed</span>}
                  </div>
                  
                  <p className="text-gray-600 mb-3">{caseItem.description}</p>
                  
                  <div className="flex items-center space-x-6 text-sm text-gray-500">
                    <span>Alerts: {caseItem.alert_count || 0}</span>
                    <span>•</span>
                    <span>Assigned: {caseItem.assigned_to_email || 'Unassigned'}</span>
                    <span>•</span>
                    <span>Created: {new Date(caseItem.created_at).toLocaleDateString()}</span>
                  </div>
                </div>
                
                <div className="ml-4">
                  <button className="btn btn-primary text-sm">
                    View Details
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
