require 'rask/<%=file_name%>_task'

case ARGV[0]
when 'start'
  Rask.daemon(:class=>'<%=class_name%>Task', :process_name=>'<%=file_name%>_task')
when 'restart'
  system "/bin/kill `/bin/cat #{Rask.base_directory}/<%=file_name%>_task.pid`"
  while File.exist?("#{Rask.base_directory}/<%=file_name%>_task.pid")
    sleep 0.5
  end
  Rask.daemon(:class=>'<%=class_name%>Task', :process_name=>'<%=file_name%>_task')
when 'stop'
  system "/bin/kill `/bin/cat #{Rask.base_directory}/<%=file_name%>_task.pid`"
  while File.exist?("#{Rask.base_directory}/<%=file_name%>_task.pid")
    sleep 0.5
  end
else
  Rask.insert <%=class_name%>Task.new
end
