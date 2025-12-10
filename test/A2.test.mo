import BaseToCore "BaseToCore";
import Map "mo:core/Map";
import List "mo:core/List";
import Text "mo:core/Text";
import Principal "mo:core/Principal";
import AccessControl "authorization/access-control";
import Time "mo:core/Time";
import Nat "mo:core/Nat";

module {
  type UserProfile = {
    name : Text;
    email : Text;
    avatar : ?Text
  };

  type ProjectRole = {
    #admin;
    #member;
    #viewer
  };

  type Project = {
    id : Text;
    name : Text;
    description : Text;
    budget : Nat;
    startDate : Time.Time;
    endDate : Time.Time;
    owner : Principal
  };

  type Task = {
    id : Text;
    projectId : Text;
    title : Text;
    description : Text;
    priority : { #low; #medium; #high };
    dueDate : Time.Time;
    status : { #todo; #inProgress; #done };
    assignedTo : Principal;
    parentTaskId : ?Text
  };

  type TimeEntry = {
    id : Text;
    taskId : Text;
    userId : Principal;
    hours : Nat;
    date : Time.Time
  };

  type FileAttachment = {
    id : Text;
    projectId : Text;
    taskId : ?Text;
    fileName : Text;
    fileType : Text;
    fileSize : Nat;
    uploadDate : Time.Time;
    uploadedBy : Principal
  };

  type TaskHistory = {
    id : Text;
    taskId : Text;
    action : Text;
    timestamp : Time.Time;
    performedBy : Principal
  };

  type OldActor = {
    var userProfiles : Map.Map<Principal, UserProfile>;
    var projectRoles : Map.Map<Text, Map.Map<Principal, ProjectRole>>;
    var projects : Map.Map<Text, Project>;
    var tasks : Map.Map<Text, Task>;
    var timeEntries : Map.Map<Text, TimeEntry>;
    var fileAttachments : Map.Map<Text, FileAttachment>;
    var taskHistories : Map.Map<Text, List.List<TaskHistory>>;
    accessControlState : BaseToCore.OldAccessControlState
  };

  type NewActor = {
    var userProfiles : Map.Map<Principal, UserProfile>;
    var projectRoles : Map.Map<Text, Map.Map<Principal, ProjectRole>>;
    var projects : Map.Map<Text, Project>;
    var tasks : Map.Map<Text, Task>;
    var timeEntries : Map.Map<Text, TimeEntry>;
    var fileAttachments : Map.Map<Text, FileAttachment>;
    var taskHistories : Map.Map<Text, List.List<TaskHistory>>;
    accessControlState : BaseToCore.NewAccessControlState
  };

  public func run(old : OldActor) : NewActor {
    {
      var userProfiles = old.userProfiles;
      var projectRoles = old.projectRoles;
      var projects = old.projects;
      var tasks = old.tasks;
      var timeEntries = old.timeEntries;
      var fileAttachments = old.fileAttachments;
      var taskHistories = old.taskHistories;
      accessControlState = BaseToCore.migrateAccessControlState(old.accessControlState)
    }
  }
}
