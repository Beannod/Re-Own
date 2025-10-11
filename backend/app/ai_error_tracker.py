import json
import traceback
import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional
import inspect

class AIErrorTracker:
    """
    Advanced error tracking system designed for AI analysis and recognition.
    Logs errors in structured JSON format with context and metadata.
    """
    
    def __init__(self, log_file: str = "ai_error_log.json"):
        self.log_file = Path(log_file)
        self.session_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.setup_logging()
        
    def setup_logging(self):
        """Setup structured logging for AI analysis"""
        logging.basicConfig(
            level=logging.DEBUG,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('debug.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def log_error(self, 
                  error: Exception, 
                  context: str = "", 
                  user_action: str = "",
                  endpoint: str = "",
                  request_data: Dict = None,
                  severity: str = "ERROR") -> Dict[str, Any]:
        """
        Log error in AI-readable structured format
        
        Args:
            error: The exception that occurred
            context: Description of what was happening when error occurred
            user_action: What the user was trying to do
            endpoint: API endpoint involved (if any)
            request_data: Request data that caused the error
            severity: ERROR, WARNING, CRITICAL, INFO
        """
        
        # Get caller information
        frame = inspect.currentframe()
        caller_frame = frame.f_back
        caller_info = {
            "file": caller_frame.f_code.co_filename,
            "function": caller_frame.f_code.co_name,
            "line": caller_frame.f_lineno
        }
        
        error_entry = {
            "timestamp": datetime.now().isoformat(),
            "session_id": self.session_id,
            "severity": severity,
            "error_type": type(error).__name__,
            "error_message": str(error),
            "traceback": traceback.format_exc(),
            "context": context,
            "user_action": user_action,
            "endpoint": endpoint,
            "request_data": request_data or {},
            "caller_info": caller_info,
            "python_version": sys.version,
            "ai_analysis_tags": self._generate_ai_tags(error, context, user_action),
            "suggested_fixes": self._suggest_fixes(error, context),
            "error_pattern": self._identify_pattern(error, context, endpoint)
        }
        
        # Log to console for immediate visibility
        self.logger.error(f"AI_ERROR_TRACKER: {json.dumps(error_entry, indent=2)}")
        
        # Append to JSON log file for AI analysis
        self._append_to_json_log(error_entry)
        
        return error_entry
    
    def _generate_ai_tags(self, error: Exception, context: str, user_action: str) -> list:
        """Generate tags for AI pattern recognition"""
        tags = []
        
        # Error type tags
        error_type = type(error).__name__
        tags.append(f"error_type:{error_type}")
        
        # Common error patterns
        error_msg = str(error).lower()
        if "module" in error_msg and "not found" in error_msg:
            tags.append("pattern:missing_module")
        elif "connection" in error_msg:
            tags.append("pattern:connection_issue")
        elif "database" in error_msg or "sql" in error_msg:
            tags.append("pattern:database_error")
        elif "auth" in error_msg or "token" in error_msg:
            tags.append("pattern:authentication_error")
        elif "permission" in error_msg or "access" in error_msg:
            tags.append("pattern:permission_error")
        elif "timeout" in error_msg:
            tags.append("pattern:timeout_error")
        elif "validation" in error_msg or "invalid" in error_msg:
            tags.append("pattern:validation_error")
        
        # Context tags
        if context:
            context_lower = context.lower()
            if "registration" in context_lower:
                tags.append("context:user_registration")
            elif "login" in context_lower:
                tags.append("context:user_login")
            elif "api" in context_lower:
                tags.append("context:api_call")
            elif "database" in context_lower:
                tags.append("context:database_operation")
        
        # User action tags
        if user_action:
            action_lower = user_action.lower()
            if "register" in action_lower:
                tags.append("user_action:registration")
            elif "login" in action_lower:
                tags.append("user_action:login")
            elif "create" in action_lower:
                tags.append("user_action:create_data")
            elif "update" in action_lower:
                tags.append("user_action:update_data")
        
        return tags
    
    def _suggest_fixes(self, error: Exception, context: str) -> list:
        """AI-friendly suggested fixes based on error patterns"""
        suggestions = []
        error_msg = str(error).lower()
        error_type = type(error).__name__
        
        if error_type == "ModuleNotFoundError":
            module_name = str(error).split("'")[1] if "'" in str(error) else "unknown"
            suggestions.append({
                "fix": f"Install missing module: pip install {module_name}",
                "command": f"pip install {module_name}",
                "priority": "HIGH"
            })
        
        elif error_type == "AttributeError":
            suggestions.append({
                "fix": "Check if object exists before accessing attribute",
                "code_pattern": "if hasattr(obj, 'attribute'): obj.attribute",
                "priority": "MEDIUM"
            })
        
        elif "database" in error_msg or "sql" in error_msg:
            suggestions.extend([
                {
                    "fix": "Check database connection",
                    "command": "Test database connectivity",
                    "priority": "HIGH"
                },
                {
                    "fix": "Verify database credentials",
                    "priority": "HIGH"
                },
                {
                    "fix": "Check if database/table exists",
                    "priority": "MEDIUM"
                }
            ])
        
        elif "connection" in error_msg:
            suggestions.extend([
                {
                    "fix": "Check network connectivity",
                    "priority": "HIGH"
                },
                {
                    "fix": "Verify server is running",
                    "priority": "HIGH"
                },
                {
                    "fix": "Check firewall/port settings",
                    "priority": "MEDIUM"
                }
            ])
        
        return suggestions
    
    def _identify_pattern(self, error: Exception, context: str, endpoint: str) -> Dict[str, Any]:
        """Identify error patterns for AI learning"""
        pattern = {
            "error_category": self._categorize_error(error),
            "frequency_indicator": f"{type(error).__name__}_{context}_{endpoint}",
            "complexity_level": self._assess_complexity(error, context),
            "user_impact": self._assess_user_impact(error, context),
            "fix_difficulty": self._assess_fix_difficulty(error)
        }
        return pattern
    
    def _categorize_error(self, error: Exception) -> str:
        """Categorize error for AI pattern recognition"""
        error_type = type(error).__name__
        
        categories = {
            "ModuleNotFoundError": "DEPENDENCY",
            "ImportError": "DEPENDENCY", 
            "AttributeError": "CODE_LOGIC",
            "TypeError": "CODE_LOGIC",
            "ValueError": "DATA_VALIDATION",
            "KeyError": "DATA_ACCESS",
            "IndexError": "DATA_ACCESS",
            "ConnectionError": "NETWORK",
            "TimeoutError": "NETWORK",
            "PermissionError": "SYSTEM",
            "FileNotFoundError": "SYSTEM"
        }
        
        return categories.get(error_type, "UNKNOWN")
    
    def _assess_complexity(self, error: Exception, context: str) -> str:
        """Assess error complexity for AI prioritization"""
        error_msg = str(error).lower()
        
        if any(word in error_msg for word in ["module", "import", "install"]):
            return "LOW"
        elif any(word in error_msg for word in ["database", "connection", "network"]):
            return "MEDIUM"
        elif any(word in error_msg for word in ["permission", "access", "auth"]):
            return "HIGH"
        else:
            return "MEDIUM"
    
    def _assess_user_impact(self, error: Exception, context: str) -> str:
        """Assess user impact for AI prioritization"""
        context_lower = context.lower()
        
        if any(word in context_lower for word in ["login", "register", "auth"]):
            return "CRITICAL"
        elif any(word in context_lower for word in ["create", "save", "update"]):
            return "HIGH"
        elif any(word in context_lower for word in ["view", "display", "show"]):
            return "MEDIUM"
        else:
            return "LOW"
    
    def _assess_fix_difficulty(self, error: Exception) -> str:
        """Assess fix difficulty for AI planning"""
        error_type = type(error).__name__
        
        easy_fixes = ["ModuleNotFoundError", "ImportError", "FileNotFoundError"]
        medium_fixes = ["AttributeError", "TypeError", "ValueError"]
        hard_fixes = ["ConnectionError", "PermissionError", "DatabaseError"]
        
        if error_type in easy_fixes:
            return "EASY"
        elif error_type in medium_fixes:
            return "MEDIUM"
        elif error_type in hard_fixes:
            return "HARD"
        else:
            return "MEDIUM"
    
    def _append_to_json_log(self, error_entry: Dict[str, Any]):
        """Append error to JSON log file for AI analysis"""
        try:
            # Read existing log
            if self.log_file.exists():
                with open(self.log_file, 'r') as f:
                    data = json.load(f)
            else:
                data = {"errors": [], "metadata": {"created": datetime.now().isoformat()}}
            
            # Add new error
            data["errors"].append(error_entry)
            data["metadata"]["last_updated"] = datetime.now().isoformat()
            data["metadata"]["total_errors"] = len(data["errors"])
            
            # Write back to file
            with open(self.log_file, 'w') as f:
                json.dump(data, f, indent=2, default=str)
                
        except Exception as e:
            self.logger.error(f"Failed to write to AI error log: {e}")
    
    def get_error_summary(self) -> Dict[str, Any]:
        """Get AI-readable error summary"""
        try:
            if not self.log_file.exists():
                return {"message": "No errors logged yet"}
            
            with open(self.log_file, 'r') as f:
                data = json.load(f)
            
            errors = data.get("errors", [])
            
            # Generate summary
            summary = {
                "total_errors": len(errors),
                "session_id": self.session_id,
                "error_types": {},
                "patterns": {},
                "severity_breakdown": {},
                "recent_errors": errors[-5:] if errors else []
            }
            
            for error in errors:
                # Count error types
                error_type = error.get("error_type", "Unknown")
                summary["error_types"][error_type] = summary["error_types"].get(error_type, 0) + 1
                
                # Count patterns
                for tag in error.get("ai_analysis_tags", []):
                    summary["patterns"][tag] = summary["patterns"].get(tag, 0) + 1
                
                # Count severity
                severity = error.get("severity", "Unknown")
                summary["severity_breakdown"][severity] = summary["severity_breakdown"].get(severity, 0) + 1
            
            return summary
            
        except Exception as e:
            return {"error": f"Failed to generate summary: {e}"}

# Global instance for easy access
ai_tracker = AIErrorTracker()

def track_error(error: Exception, 
                context: str = "", 
                user_action: str = "",
                endpoint: str = "",
                request_data: Dict = None,
                severity: str = "ERROR") -> Dict[str, Any]:
    """
    Global function to track errors for AI analysis
    
    Usage:
        try:
            # some code
        except Exception as e:
            track_error(e, 
                       context="User registration process",
                       user_action="Trying to register new account",
                       endpoint="/api/auth/register",
                       request_data={"email": "user@example.com"})
    """
    return ai_tracker.log_error(error, context, user_action, endpoint, request_data, severity)