#!/bin/bash

# This is used to start the IBM MQ monitoring service for OpenTelemetry

# The queue manager name comes in from the service definition as the
# only command line parameter
qMgr=$1

# Set the environment to ensure we pick up libmqm.so etc
# If this is a client connection, then deal with no known qmgr of the given name.
. /opt/mqm/bin/setmqenv -m $qMgr -k >/dev/null 2>&1
if [ $? -ne 0 ]
then
  . /opt/mqm/bin/setmqenv -s -k
fi

if false
then
  # One way of providing configuration information is directly via the command-line flags
  # This shows how it can be done. but the preferred mechanism is through a separate
  # YAML configuration file.

  # A list of queues to be monitored is given here.
  # It is a set of names or patterns ('*' only at the end, to match how MQ works),
  # separated by commas. When no queues match a pattern, it is reported but
  # is not fatal.
  queues="APP.*,MYQ.*"

  # An alternative is to have a file containing the patterns, and named
  # via the ibmmq.monitoredQueuesFile option.

  # And other parameters that may be needed
  # See config.go for all recognised flags

  interval="10s"

  ARGS="-ibmmq.queueManager=$qMgr"
  ARGS="$ARGS -ibmmq.interval=$interval"
  ARGS="$ARGS -ibmmq.monitoredQueues=$queues"
  ARGS="$ARGS -ibmmq.monitoredChannels=*"
  ARGS="$ARGS -ibmmq.useStatus=true"
  ARGS="$ARGS -log.level=error"
else
  # This is the preferred mechanism for configuration outside of
  # containers where the equivalent environment variables are more common
  ARGS="-f=/usr/local/bin/mqgo/mq_otel.yaml"
fi

# Start via "exec" so the pid remains the same. The queue manager can
# then check the existence of the service and use the MQ_SERVER_PID value
# to kill it on shutdown.
exec /usr/local/bin/mqgo/mq_otel  $ARGS
