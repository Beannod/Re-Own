"""
Example usage:

from .logging_config import get_logger, log_exception

# Get logger for app
app_logger = get_logger('app')
app_logger.info('Application started')

# Get logger for API
api_logger = get_logger('api')
api_logger.warning('API warning example')

# Log an exception with traceback
try:
    1 / 0
except Exception as exc:
    log_exception(app_logger, 'Unhandled exception occurred', exc)
"""
import logging
import os

LOG_DIR = os.path.join(os.path.dirname(__file__), '../../logs')

LOG_FILES = {
    'app': 'app.log',
    'api': 'api.log',
    'auth': 'auth.log',
    'database': 'database.log',
    'security': 'security.log',
    'frontend_errors': 'frontend_errors.log',
    'python_errors': 'python_errors.log',
    'performance': 'performance.log',
    'user_activity': 'user_activity.log',
    'background_tasks': 'background_tasks.log',
}

def get_logger(name, level=logging.INFO):
    logger = logging.getLogger(name)
    if not logger.hasHandlers():
        log_file = os.path.join(LOG_DIR, LOG_FILES.get(name, f'{name}.log'))
        handler = logging.FileHandler(log_file)
        formatter = logging.Formatter('%(asctime)s %(levelname)s %(name)s %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.setLevel(level)
    return logger

def log_exception(logger, msg, exc):
    logger.error(msg, exc_info=exc)
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