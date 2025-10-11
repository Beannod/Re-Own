import logging
import os
from logging.handlers import RotatingFileHandler
import sys
from datetime import datetime

def clear_logs(logs_dir):
    """Clear all log files in the logs directory"""
    if os.path.exists(logs_dir):
        for log_file in os.listdir(logs_dir):
            if log_file.endswith('.log'):
                file_path = os.path.join(logs_dir, log_file)
                try:
                    # Open the file in write mode, which clears its contents
                    with open(file_path, 'w') as f:
                        f.write(f"Log cleared at {datetime.now().isoformat()}\n")
                except Exception as e:
                    print(f"Failed to clear log file {log_file}: {e}")

def setup_logging():
    # Create logs directory if it doesn't exist
    logs_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'logs')
    os.makedirs(logs_dir, exist_ok=True)
    
    # Clear existing logs
    clear_logs(logs_dir)

    # Configure different log files for different purposes
    log_files = {
        'auth': os.path.join(logs_dir, 'auth.log'),
        'api': os.path.join(logs_dir, 'api.log'),
        'database': os.path.join(logs_dir, 'database.log'),
        'security': os.path.join(logs_dir, 'security.log'),
        'general': os.path.join(logs_dir, 'app.log')
    }

    # Basic logging format
    log_format = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    # Setup handlers for each log file
    handlers = {}
    for name, filepath in log_files.items():
        handler = RotatingFileHandler(
            filepath,
            maxBytes=10*1024*1024,  # 10MB
            backupCount=5
        )
        handler.setFormatter(log_format)
        handlers[name] = handler

    # Configure loggers
    loggers = {
        'auth': logging.getLogger('auth'),
        'api': logging.getLogger('api'),
        'database': logging.getLogger('database'),
        'security': logging.getLogger('security'),
        'app': logging.getLogger('app')
    }

    # Set up each logger
    for name, logger in loggers.items():
        logger.setLevel(logging.DEBUG)
        logger.addHandler(handlers.get(name if name != 'app' else 'general'))
        # Add console handler in development
        if os.getenv('ENVIRONMENT') != 'production':
            console_handler = logging.StreamHandler(sys.stdout)
            console_handler.setFormatter(log_format)
            logger.addHandler(console_handler)

    return loggers

# Global logger instances
loggers = setup_logging()
auth_logger = loggers['auth']
api_logger = loggers['api']
db_logger = loggers['database']
security_logger = loggers['security']
app_logger = loggers['app']