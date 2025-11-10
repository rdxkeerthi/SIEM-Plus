"""SOAR Playbook Engine"""

import yaml
import logging
from typing import Dict, Any, List
from .connectors import get_connector

logger = logging.getLogger(__name__)


class PlaybookEngine:
    """Execute SOAR playbooks"""

    def __init__(self):
        self.connectors = {}

    def load_playbook(self, playbook_path: str) -> Dict[str, Any]:
        """Load playbook from YAML file"""
        with open(playbook_path, 'r') as f:
            return yaml.safe_load(f)

    def execute_playbook(self, playbook: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a playbook with given context"""
        logger.info(f"Executing playbook: {playbook.get('name')}")
        
        results = {
            'playbook_name': playbook.get('name'),
            'status': 'success',
            'actions': []
        }

        try:
            for action in playbook.get('actions', []):
                action_result = self.execute_action(action, context)
                results['actions'].append(action_result)
                
                if action_result['status'] == 'failed':
                    results['status'] = 'failed'
                    break

        except Exception as e:
            logger.error(f"Playbook execution failed: {e}")
            results['status'] = 'failed'
            results['error'] = str(e)

        return results

    def execute_action(self, action: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a single action"""
        action_type = action.get('type')
        params = action.get('params', {})

        logger.info(f"Executing action: {action_type}")

        try:
            if action_type == 'assign_alert':
                return self._assign_alert(params, context)
            elif action_type == 'send_notification':
                return self._send_notification(params, context)
            elif action_type == 'isolate_host':
                return self._isolate_host(params, context)
            elif action_type == 'create_ticket':
                return self._create_ticket(params, context)
            else:
                return {
                    'action': action_type,
                    'status': 'failed',
                    'error': f'Unknown action type: {action_type}'
                }

        except Exception as e:
            logger.error(f"Action {action_type} failed: {e}")
            return {
                'action': action_type,
                'status': 'failed',
                'error': str(e)
            }

    def _assign_alert(self, params: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Assign alert to user"""
        # TODO: Call manager API to assign alert
        return {
            'action': 'assign_alert',
            'status': 'success',
            'user': params.get('user')
        }

    def _send_notification(self, params: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Send notification via connector"""
        channel = params.get('channel')
        connector = get_connector(channel)
        
        if connector:
            connector.send(params.get('message'), context)
            return {
                'action': 'send_notification',
                'status': 'success',
                'channel': channel
            }
        else:
            return {
                'action': 'send_notification',
                'status': 'failed',
                'error': f'Unknown channel: {channel}'
            }

    def _isolate_host(self, params: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Isolate compromised host"""
        # TODO: Send isolation command to agent
        return {
            'action': 'isolate_host',
            'status': 'success',
            'host': params.get('host')
        }

    def _create_ticket(self, params: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
        """Create ticket in external system"""
        system = params.get('system')
        connector = get_connector(system)
        
        if connector:
            ticket_id = connector.create_ticket(params, context)
            return {
                'action': 'create_ticket',
                'status': 'success',
                'system': system,
                'ticket_id': ticket_id
            }
        else:
            return {
                'action': 'create_ticket',
                'status': 'failed',
                'error': f'Unknown system: {system}'
            }
