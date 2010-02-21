#
# Rask library
# (c)2010 mewlist
#
require 'fileutils'
require 'thread'

require File.dirname(__FILE__) + '/rask/state_machine'


module Rask
  
  class Task
    include StateMachine
    attr_accessor :task_id
    attr_accessor :group
    
    def initialize(_group=nil)
      group = _group
      super()
    end
    
    
    def run
      if @state
        eval @state.to_s
      end
    end
    
    
    def transition(to)
      @state = to
    end
    
    
    def destroy
      transition nil
    end
    
    
    def destroy?
      @state == nil
    end
    
  end
  
  
  @@base_dir     = '/tmp/rask'
  @@threading    = false
  @@thread_count = 5
  @@queue        = Queue.new
  @@processing   = []
  @@locker       = Mutex::new
 
  def self.base_directory=(new_directory)
    @@base_dir = new_directory
  end
  
  def self.enable_thread
    @@threading = true
  end
  
  def self.disable_thread
    @@threading = false
  end
  
  def self.thread_count=(count)
    @@thread_count = count
  end
  
  def self.task_path(task_id)
    @@base_dir+"/#{task_id}.task"
  end
  
  def self.insert(task)
    initialize_storage
    task_id = "#{safe_class_name(task.class.name)}-#{task.group.to_s}-#{Time.now.to_i}-#{Time.now.usec}"
    task.task_id = task_id
    FileUtils.touch(task_path(task_id)) unless File.exists? task_path(task_id)
    f = File.open(task_path(task_id), 'w')
    f.flock(File::LOCK_EX)
    Marshal.dump(task, f)
    f.flock(File::LOCK_UN)
    f.close
  end
  
  
  def self.run(task_path)
    f = File.open(task_path, 'r+') rescue return
    f.flock(File::LOCK_EX)
    
    task = Marshal.restore(f)
    yield task
    
    f.truncate(0)
    f.pos = 0
    Marshal.dump(task, f)
    f.flock(File::LOCK_UN)
    f.close
    FileUtils.rm(task_path) if task.destroy?
  end
  
  def self.each(options = { :class=>nil, :group=>nil }, &blk)
    threads = []
    tasks(options).each { |d|
      if @@threading
        threads << Thread::new(d) { |task_path| run(task_path, &blk) }
      else
        run(d, &blk)
      end
    }
    threads.each { |t| t.join } if @@threading
  end
  
  def self.tasks(options = { :class=>nil, :group=>nil })
    target = @@base_dir
    target += '/' if options[:class] || options[:group]
    target += "#{safe_class_name(options[:class])}" if options[:class]
    target += "-#{options[:group]}-" if options[:group]
    
    task_list = []
    Dir.glob(@@base_dir+"/*.task") { |d|
      if target.empty? || /#{target}/ =~ d
        task_list.push d
      end
    }
    task_list
  end
  
  def self.initialize_storage
    unless File.exists? @@base_dir
      FileUtils.makedirs @@base_dir
    end
  end
  
  def self.destroy(task)
    FileUtils.rm(task_path(task.task_id)) if File.exists? task_path(task.task_id)
  end
  
  def self.safe_class_name(c)
    c.gsub(/[:]/,'@')
  end

  def self.daemon(options = { :pname=>"Rask", :class=>nil, :group=>nil, :sleep=>0.1 })
    print "daemon start\n"
    exit if fork
    Process.setsid
    open(@@base_dir+"/#{options[:pname]}.pid","w"){|f| f.write Process.pid}
    
    # create worker threads
    threads = []
    for i in 1..@@thread_count do 
      threads << Thread::new{
        while true
          d = nil
          @@locker.synchronize do
            d = @@queue.pop unless @@queue.empty?
          end
          if d != nil
#            print "#{d}\n"
            run(d) { |task| task.run }
            @@locker.synchronize do
              @@processing.delete(d)
            end
          else
#            print "no data in queue\n"
            sleep(options[:sleep])
          end
        end
      }
    end
    
    while true
      task_list = Rask.tasks(options)
      task_list.each { |d|
        @@locker.synchronize do
          unless @@processing.include?(d)
            @@queue.push d
            @@processing.push d
          end
        end
      }
      sleep(options[:sleep])
    end
  end
  
end  

