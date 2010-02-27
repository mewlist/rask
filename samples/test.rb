require 'rubygems'
require 'rask'

# 数値のカウントアップ 10 までカウントするタスク
class CountupTask < Rask::Task
  # define_state でステートマシンを作ることができます
  define_state :start,   :initial => true       # 初期状態
  define_state :running                         # 実行
  define_state :finish,  :from    => [:running] # 終了 (遷移元は:runningからのみ)
  
  def start # 定義と同名の関数を定義することで自動的にコールバックされます
    @count = 0
    p "start"
    transition_to_running # :running へ遷移
  end
  
  def running
    p "running count => #{@count+=1}"
    transition_to_finish if @count>=10 # :finish へ遷移
  end
  
  def finish
    p "finished"
    destroy # タスクの破棄をする
  end
end

Rask.insert CountupTask.new # タスクの登録

Rask.daemon # デーモンとして実行

