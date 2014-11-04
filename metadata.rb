name             'opsworks-rolling-restart'
maintainer       'Sport Ngin'
maintainer_email 'platform-ops@sportngin.com'
license          'MIT'
description      'Provides a rolling restart orchistration to be used with on any appliction with a single restart command'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.markdown'))
version          '0.1.0'

supports 'redhat'

depends 'haproxy'
