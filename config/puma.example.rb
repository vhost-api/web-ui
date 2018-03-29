# frozen_string_literal: true

environment 'production'

pidfile 'puma.pid'

threads 2, 4
workers 2
preload_app!
daemonize false

bind 'tcp://127.0.0.1:9494'
