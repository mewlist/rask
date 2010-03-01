require 'rask/<%=file_name%>_task'

base_directory = RAILS_ROOT+"/tmp/rask"
Rask.base_directory = base_directory
Rask.process_name   = '<%=file_name%>_task'

case ARGV[0]
when 'start'
  Rask.daemon(:class=>'<%=class_name%>Task')
when 'restart'
  system "/bin/kill `/bin/cat #{base_directory}/<%=file_name%>_task.pid`"
  while File.exist?("#{base_directory}/<%=file_name%>_task.pid")
    sleep 0.5
  end
  Rask.daemon(:class=>'<%=class_name%>Task')
when 'stop'
  system "/bin/kill `/bin/cat #{base_directory}/<%=file_name%>_task.pid`"
  while File.exist?("#{base_directory}/<%=file_name%>_task.pid")
    sleep 0.5
  end
else
  Rask.insert <%=class_name%>Task.new
end


