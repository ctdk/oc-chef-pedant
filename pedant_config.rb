# This annotated Pedant configuration file details the various
# configuration settings available to you.  It is separate from the
# actual Pedant::Config class because not all settings have sane
# defaults, and not all settings are appropriate in all settings.

################################################################################

# Specify a testing organization if you are testing a multi-tenant
# instance of a Chef Server (e.g., Private Chef, Hosted Chef).  If you
# are testing a single-tenant instance (i.e. Open Source Chef Server),
# DO NOT include this parameter
#
# Due to how the current org cache operates, it is best to use a
# randomized name for your testing organization (hence the embedded
# Process.pid).  If you do not use a randomized name and run tests
# several times (destroying the organization between runs) you will
# likely get inconsistent results.
#
# If you wish Pedant to create the organization for you at test time,
# include the `:create_me => true` pair.  If you wish to use an
# existing organization for tests, you should supply a `:validator_key
# => "/full/path/to/key.pem"` pair
org({:name => "pedant-testorg-#{Process.pid}",
     :create_me => true})

# org({:name => "existing_org",
#      :validator_key => "/etc/opscode/existing_org-validator.pem"})

# account internal URL
internal_account_url "http://localhost:9685"

# If you want Pedant to delete the testing organization when it is
# done, use this parameter.  Note that this only has an effect if
# Pedant also created the testing organization.
delete_org true

# You MUST specify the address of the server the API requests will be
# sent to.  Only specify protocol, hostname, and port.
chef_server "http://#{`hostname -f`.strip}:4545"

# If you are doing development testing, you can specify the address of
# the Solr server.  The presence of this parameter will enable tests
# to force commits to Solr, greatly decreasing the amout of time
# needed for testing the search endpoint.  This is only an
# optimization for development!  If you are testing a "live" Chef
# Server, or otherwise do not have access to the Solr server from your
# testing location, you should not specify a value for this parameter.
# The tests will still run, albeit slower, as they will now need to
# poll for a period to ensure they are querying committed results.
search_server "http://localhost:8983"

# Related to the 'search_server' parameter, this specifies the maximum
# amout of time (in seconds) that search endpoint requests should be
# retried before giving up.  If not explicitly set, it will default to
# 65 seconds; only set it if you know that your Solr commit interval
# differs significantly from this.
maximum_search_time 65

# We're starting to break tests up into groups based on different
# criteria.  The proper API tests (the results of which are viewable
# to OPC customers) should be the only ones run by Pedant embedded in
# OPC installs.  There are other specs that help us keep track of API
# cruft that we want to come back and fix later; these shouldn't be
# viewable to customers, but we should be able to run them in
# development and CI environments.  If this parameter is missing or
# explicitly `false` only the customer-friendly tests will be run.
#
# This is mainly here for documentation purposes, since the
# command-line `opscode-pedant` utility ultimately determines this
# value.
include_internal false

##########################################################
# LDAP Testing, see the README.md for additional details #
##########################################################

# Set to true if you wish do LDAP testing on authenticate_user and system_recovery tests
ldap_testing false

# Fill in the following with correct values for your AD user if ldap_testing is true (directly above)
# Put :key => nil if there is no value
ldap({
       # Change this to your AD samAccountName (i.e., my login name) for your test server
       :account_name => "your_ldap_account_name",
       # Change this to your current AD password for your test server
       :account_password => "your_ldap_password!",
       # Your first name in AD
       :first_name => "Firsname",
       # Your last name in AD
       :last_name => "Lastname",
       # Your display name in AD, likely "Firstname Lastname"
       :display_name => "Firstname Lastname",
       # Your email in AD
       :email => "your@email.com",
       # Likely nil
       :city => nil,
       # Likely nil
       :country => nil,
       # Set to "linked" or "unlinked" depending on the status of your account in AD
       :status => "unlinked",
       # Set to true or false, depending on your user state in Chef itself
       :recovery_authentication_enabled => false
     })


# Test users.  The five users specified below are required; their
# names (:user, :non_org_user, etc.) are indicative of their role
# within the tests.  All users must have a ':name' key.  If they have
# a ':create_me' key, Pedant will create these users for you.  If you
# are using pre-existing users, you must supply a ':key_file' key,
# which should be the fully-qualified path /on the machine Pedant is
# running on/ to a private key for that user.


superuser_name 'pivotal'
superuser_key  '/etc/chef-server/pivotal.pem'

webui_key '/etc/chef-server/default-webui.pem'

requestors({
             :clients => {
               # The the admin user, for the purposes of getting things rolling
               :admin => {
                 :name => "pedant_admin_client",
                 :create_me => true,
                 :create_knife => true,
                 :admin => true
               },
               :non_admin => {
                 :name => 'pedant_client',
                 :create_me => true,
                 :create_knife => true,
               },
               :bad => {
                 :name => 'bad_client',
                 :create_me => true,
                 :create_knife => true,
                 :bogus => true
               }
             },

             :users => {
               # An administrator in the testing organization
               :admin => {
                 :name => "pedant_admin_user",
                 :create_me => true,
                 :create_knife => true,
		 :admin => true
               },

               :non_admin => {
                 :name => "pedant_user",
                 :create_me => true,
                 :create_knife => true
               },

               # A user that is not a member of the testing organization
               :bad => {
                 :name => "pedant-nobody",
                 :create_me => true,
                 :create_knife => true,
                 :associate => false
               },
             }
           })



# users({

#     # A "normal" (non-admin) user in the testing organization
#     :user => {
#       :name => "pedant-normal",
#       :create_me => true
#     },

#     # A user that is not a member of the testing organization
#     :non_org_user => {
#       :name => "pedant-nobody",
#       :create_me => true
#     },

#     # An administrator in the testing organization
#     :admin_user => {
#       :name => "pedant-admin",
#       :create_me => true
#     },


#     # A user for Knife tests.  A knife.rb and key files will be set up
#     # for this user
#     :knife_user => {
#       :name => "knifey",
#       :create_me => true
#     }
#   })

# To facilitate testing as we transition from Ruby to Erlang endpoint
# implementations, you can specify in your configuration which
# implementation for each endpoint is currently active on the system
# under test.  Tests should be written to fork on this value if
# necessary.  A common reason is to take into account different error
# message formatting between the two implementations.
#
ruby_users_endpoint? false
ruby_org_assoc? false
ruby_org_acl_endpoint? false
ruby_organizations_endpoint? false
ruby_org_endpoint? false
