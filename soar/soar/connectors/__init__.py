"""SOAR Connectors"""

from typing import Optional

def get_connector(name: str) -> Optional[object]:
    """Get connector by name"""
    if name == 'slack':
        from .slack import SlackConnector
        return SlackConnector()
    elif name == 'jira':
        from .jira import JiraConnector
        return JiraConnector()
    else:
        return None
