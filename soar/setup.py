from setuptools import setup, find_packages

setup(
    name="siem-plus-soar",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "pyyaml>=6.0",
        "requests>=2.31.0",
        "celery>=5.3.0",
        "redis>=5.0.0",
        "sqlalchemy>=2.0.0",
        "psycopg2-binary>=2.9.0",
        "pydantic>=2.5.0",
    ],
)
