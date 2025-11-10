import { useQuery } from '@tanstack/react-query'
import { ShieldCheckIcon } from '@heroicons/react/24/outline'
import axios from 'axios'
import { useAuthStore } from '../stores/authStore'

export default function Rules() {
  const { token } = useAuthStore()

  const { data: rulesData } = useQuery({
    queryKey: ['rules'],
    queryFn: async () => {
      const response = await axios.get('/api/v1/rules', {
        headers: { Authorization: `Bearer ${token}` },
      })
      return response.data
    },
  })

  const rules = rulesData?.rules || []

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Detection Rules</h1>
          <p className="mt-2 text-gray-600">Manage Sigma rules and custom detections</p>
        </div>
        <button className="btn btn-primary">
          <ShieldCheckIcon className="w-5 h-5 mr-2 inline" />
          Create Rule
        </button>
      </div>

      <div className="card">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead>
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Rule Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Type
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Severity
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Tags
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {rules.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                    <ShieldCheckIcon className="w-12 h-12 mx-auto text-gray-400 mb-4" />
                    <p>No detection rules configured</p>
                    <p className="text-sm mt-2">Create your first rule to start detecting threats</p>
                  </td>
                </tr>
              ) : (
                rules.map((rule: any) => (
                  <tr key={rule.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div>
                        <div className="font-medium text-gray-900">{rule.name}</div>
                        <div className="text-sm text-gray-500">{rule.description}</div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="badge badge-info">{rule.rule_type}</span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {rule.severity === 'critical' && <span className="badge badge-danger">Critical</span>}
                      {rule.severity === 'high' && <span className="badge bg-orange-100 text-orange-800">High</span>}
                      {rule.severity === 'medium' && <span className="badge badge-warning">Medium</span>}
                      {rule.severity === 'low' && <span className="badge badge-info">Low</span>}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {rule.enabled ? (
                        <span className="badge badge-success">Enabled</span>
                      ) : (
                        <span className="badge bg-gray-100 text-gray-800">Disabled</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex flex-wrap gap-1">
                        {rule.tags?.slice(0, 3).map((tag: string, idx: number) => (
                          <span key={idx} className="badge bg-gray-100 text-gray-700 text-xs">
                            {tag}
                          </span>
                        ))}
                        {rule.tags?.length > 3 && (
                          <span className="badge bg-gray-100 text-gray-700 text-xs">
                            +{rule.tags.length - 3}
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button className="text-primary-600 hover:text-primary-900 mr-4">
                        Edit
                      </button>
                      <button className="text-gray-600 hover:text-gray-900 mr-4">
                        Test
                      </button>
                      <button className="text-red-600 hover:text-red-900">
                        Delete
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
