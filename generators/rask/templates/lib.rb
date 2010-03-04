require 'rubygems'
require 'rask'
Rask.base_directory = RAILS_ROOT+"/tmp/rask"

# background task
class <%=class_name%>Task < Rask::Task
 define_state :start,   :initial => true
 define_state :running
 define_state :finish,  :from    => [:running]

 def start
   @count = 0
   p "start <%=file_name%> task"
   transition_to_running
 end

 def running
   p "running count => #{@count+=1}"
   transition_to_finish if @count>=10
 end

 def finish
   p "finished"
   destroy
 end
end
