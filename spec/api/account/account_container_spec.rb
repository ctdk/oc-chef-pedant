# -*- coding: utf-8 -*-
require 'pedant/rspec/common'

describe "opscode-account containers", :containers do

  def self.ruby?
    Pedant::Config.ruby_container_endpoint?
  end

  def self.in_sql?
    !ruby? || Pedant::Config.ruby_container_endpoint_in_sql?
  end

  let(:in_sql?) { self.class.in_sql? }

  context "/containers endpoint" do
    let(:request_url) { api_url("containers") }

    context "GET /containers" do
      # This is only a partial body -- there are other containers as well, but these
      # should all exist for an organization:
      let(:list_of_containers) {{
          "clients" => "#{request_url}/clients",
          "containers" => "#{request_url}/containers",
          "cookbooks" => "#{request_url}/cookbooks",
          "data" => "#{request_url}/data",
          "environments" => "#{request_url}/environments",
          "groups" => "#{request_url}/groups",
          "log-infos" => "#{request_url}/log-infos",
          "nodes" => "#{request_url}/nodes",
          "reports" => "#{request_url}/reports",
          "roles" => "#{request_url}/roles",
          "sandboxes" => "#{request_url}/sandboxes",
          "shovey-keys" => "#{request_url}/shovey-keys",
          "shoveys" => "#{request_url}/shoveys"
        }}

      context "admin user" do
        it "can get containers", :smoke do
          get(request_url, platform.admin_user).should look_like({
              :status => 200,
              :body_exact => list_of_containers
            })
        end
      end

      context "normal user" do
        it "can get containers" do
          get(request_url, platform.non_admin_user).should look_like({
              :status => 200,
              :body_exact => list_of_containers
            })
        end
      end

      context "client" do
        # Is this actually right?  Seems like this should be 200
        it "returns 403", :authorization do
          get(request_url, platform.non_admin_client).should look_like({
              :status => 403
            })
        end
      end

      context "outside user" do
        it "returns 403", :authorization, :smoke do
          get(request_url, outside_user).should look_like({
              :status => 403
            })
        end
      end

      context "invalid user" do
        it "returns 401", :authentication do
          get(request_url, invalid_user).should look_like({
              :status => 401
            })
        end
      end
    end # GET /containers

    context "POST /containers" do
      let(:new_container) { "new-container" }

      let(:request_body) {{
          "containername" => new_container,
          "containerpath" => "/" # containerpath is vestigal cruft, but current
                                 # opscode-account still validates it, so we need it
        }}

      let(:response_body) {{
          "uri" => "#{request_url}/#{new_container}"
        }}

      # This is only a partial body -- there are other containers as well, but these
      # should all exist for an organization:
      let(:list_of_containers_without_new_container) {{
          "clients" => "#{request_url}/clients",
          "containers" => "#{request_url}/containers",
          "cookbooks" => "#{request_url}/cookbooks",
          "data" => "#{request_url}/data",
          "environments" => "#{request_url}/environments",
          "groups" => "#{request_url}/groups",
          "log-infos" => "#{request_url}/log-infos",
          "nodes" => "#{request_url}/nodes",
          "reports" => "#{request_url}/reports",
          "roles" => "#{request_url}/roles",
          "sandboxes" => "#{request_url}/sandboxes",
          "shovey-keys" => "#{request_url}/shovey-keys",
          "shoveys" => "#{request_url}/shoveys"
        }}

      let(:list_of_containers_with_new_container) {{
          "clients" => "#{request_url}/clients",
          "containers" => "#{request_url}/containers",
          "cookbooks" => "#{request_url}/cookbooks",
          "data" => "#{request_url}/data",
          "environments" => "#{request_url}/environments",
          "groups" => "#{request_url}/groups",
          "log-infos" => "#{request_url}/log-infos",
          "nodes" => "#{request_url}/nodes",
          "reports" => "#{request_url}/reports",
          "roles" => "#{request_url}/roles",
          "sandboxes" => "#{request_url}/sandboxes",
          "shovey-keys" => "#{request_url}/shovey-keys",
          "shoveys" => "#{request_url}/shoveys",
          new_container => "#{request_url}\/#{new_container}",
        }}

      after :each do
        begin
          delete(api_url("/containers/#{new_container}"), platform.admin_user)
        rescue
          # Swallow errors attempting to delete the invalid containers we try to create;
          # those tests should either fail before they get here or never actually
          # create the containers
        end
      end

      context "permissions" do
        context "admin user" do
          it "can create container", :smoke do
            post(request_url, platform.admin_user,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_with_new_container
              })
            get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                :status => 200
              })
          end
        end

        context "normal user" do
          it "returns 403", :authorization do
            post(request_url, platform.non_admin_user,
              :payload => request_body).should look_like({
                :status => 403
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_without_new_container
              })
            get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                :status => 404
              })
          end
        end

        context "client" do
          it "returns 403", :authorization do
            post(request_url, platform.non_admin_client,
              :payload => request_body).should look_like({
                :status => 403
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_without_new_container
              })
            get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                :status => 404
              })
          end
        end

        context "outside user" do
          it "returns 403", :authorization, :smoke do
            post(request_url, outside_user,
              :payload => request_body).should look_like({
                :status => 403
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_without_new_container
              })
            # TODO: shouldn't this properly be 403?
            get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                :status => 404
              })
          end
        end

        context "invalid user" do
          it "returns 401", :authentication do
            post(request_url, invalid_user,
              :payload => request_body).should look_like({
                :status => 401
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_without_new_container
              })
            # TODO: Shouldn't this properly be 401?
            get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                :status => 404
              })
          end
        end
      end # context Permissions

      context "container creation" do
        context "when container already exists" do
          before :each do
            post(request_url, platform.admin_user,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
          end

          it "returns 409" do
            # This sort of makes sense (default container perms are empty), but
            # still seems wrong -- no matter what the permissions are, this should
            # still be a 409
            if ruby?
              pending "returns 403 instead" do
                post(request_url, platform.admin_user,
                  :payload => request_body).should look_like({
                    :status => 409
                  })
              end
            end
          end
        end

        context "with no container name" do
          let(:request_body) {{
              "containerpath" => "/"
            }}

          it "returns 400", :validation do
            post(request_url, platform.admin_user,
              :payload => request_body).should look_like({
                :status => 400
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_without_new_container
              })
            get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                :status => 404
              })
          end
        end

        context "name instead of container name" do
          let(:request_body) {{
              "name" => new_container,
              "containerpath" => "/"
            }}

          it "returns 400", :validation do
            post(request_url, platform.admin_user,
              :payload => request_body).should look_like({
                :status => 400
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_without_new_container
              })
            get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                :status => 404
              })
          end
        end

        context "with id instead of container name" do
          let(:request_body) {{
              "id" => new_container,
              "containerpath" => "/"
            }}

          it "can create container" do
            post(request_url, platform.admin_user,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_with_new_container
              })
            get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                :status => 200
              })
          end
        end

        context "with non-matching id and container name" do
          let(:request_body) {{
              "id" => new_container,
              "containername" => "other",
              "containerpath" => "/"
            }}

          it "can create container (id wins)" do
            post(request_url, platform.admin_user,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_with_new_container
              })
            get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                :status => 200
              })
          end
        end

        context "with bogus value in request" do
          let(:request_body) {{
              "containername" => new_container,
              "dude" => "sweet",
              "containerpath" => "/"
            }}

          it "can create container (ignores bogus value)" do
            post(request_url, platform.admin_user,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_with_new_container
              })
            get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                :status => 200
              })
          end
        end

        context "with empty container name" do
          let(:new_container) { "" }

          it "returns 400", :validation do
            post(request_url, platform.admin_user,
              :payload => request_body).should look_like({
                :status => 400
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_without_new_container
              })
          end
        end

        context "with space in container name" do
          let(:new_container) { "new container" }

          it "returns 400", :validation do
            post(request_url, platform.admin_user,
              :payload => request_body).should look_like({
                :status => 400
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_without_new_container
              })
          end
        end

        context "with unicode in container name" do
          let(:new_container) { "グループ" }

          it "can create container" do
            pending "returns 400", :validation do
              post(request_url, platform.admin_user,
                :payload => request_body).should look_like({
                  :status => 201,
                  :body_exact => response_body
                })
              get(request_url, platform.admin_user).should look_like({
                  :status => 200,
                  :body_exact => list_of_containers_with_new_container
                })
              get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                  :status => 200
                })
            end
          end
        end

        context "with users, clients, and containers" do
          let(:request_body) {{
              "containername" => new_container,
              "users" => [platform.non_admin_user],
              "clients" => [platform.non_admin_client],
              "containers" => ["users"],
              "containerpath" => "/"
            }}

          let(:container_body) {{
              "containername" => new_container,
              # containerpath: a discussion took place between Mark A. and I that
              # revolved around leaving the containerpath implemented the same way
              # HEC sets it when creating a new org, which is the same as the
              # containername
              "containerpath" => in_sql? ? new_container : "/"
            }}

          it "ignores them", :validation do
            post(request_url, platform.admin_user,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.admin_user).should look_like({
                :status => 200,
                :body_exact => list_of_containers_with_new_container
              })
            get("#{request_url}/#{new_container}", platform.admin_user).should look_like({
                :status => 200,
                :body_exact => container_body
              })
          end
        end
      end # context container creation
    end # context POST /containers

    context "DELETE /containers" do

      let(:not_allowed_response) do
        if ruby?
          {:status => 404}
        else
          {
            :status => 405,
            :headers => {
              "allow" => ["GET, POST"]
            }
          }
        end
      end

      context "admin user" do
        # A 405 here would be fine (better, even)
        it "returns 404" do
          delete(request_url, platform.admin_user).should look_like(not_allowed_response)
        end
      end
    end

    context "PUT /containers" do
      let(:not_allowed_response) do
        if ruby?
          {:status => 404}
        else
          {
            :status => 405,
            :headers => {
              "allow" => ["GET, POST"]
            }
          }
        end
      end


      context "admin user" do
        # A 405 here would be fine (better, even)
        it "returns 404" do
          put(request_url, platform.admin_user).should look_like(not_allowed_response)
        end
      end
    end
  end # context /containers endpoint

  context "/containers/<name> endpoint" do
    let(:request_url) { api_url("containers/#{test_container}") }
    let(:test_container) { "test-container" }

    before :each do
      post(api_url("containers"), platform.admin_user,
        :payload => {"id" => test_container,
          "containerpath" => "/"}).should look_like({:status => 201})
    end

    after :each do
      delete(request_url, platform.admin_user)
    end

    #
    # When containers are in sql we eliminate the containerpath field and return the containername instead
    #
    let(:default_container_body) {{
        "containername" => test_container,
        "containerpath" => in_sql? ?  test_container : "/"
      }}

    context "GET /containers/<name>" do
      context "admin user" do
        it "can get container", :smoke do
          get(request_url, platform.admin_user).should look_like({
              :status => 200,
              :body_exact => default_container_body
            })
        end
      end

      context "normal user" do
        it "returns 403", :authorization do
          get(request_url, platform.non_admin_user).should look_like({
              :status => 403
            })
        end
      end

      context "client" do
        it "returns 403", :authorization do
          get(request_url, platform.non_admin_client).should look_like({
              :status => 403
            })
        end
      end

      context "outside user" do
        it "returns 403", :authorization, :smoke do
          get(request_url, outside_user).should look_like({
              :status => 403
            })
        end
      end

      context "invalid user" do
        it "returns 401", :authentication do
          get(request_url, invalid_user).should look_like({
              :status => 401
            })
        end
      end
    end # context GET /containers/<name>

    context "DELETE /containers/<name>" do
      context "admin user" do
        it "can delete container", :smoke do
          delete(request_url, platform.admin_user).should look_like({
              :status => 200
            })
          get(request_url, platform.admin_user).should look_like({
              :status => 404
            })
        end
      end

      context "normal user" do
        it "returns 403", :authorization do
          delete(request_url, platform.non_admin_user).should look_like({
              :status => 403
            })
          get(request_url, platform.admin_user).should look_like({
              :status => 200
            })
        end
      end

      context "client" do
        # Is this actually right?  Seems like this should be 200
        it "returns 403", :authorization do
          delete(request_url, platform.non_admin_client).should look_like({
              :status => 403
            })
          get(request_url, platform.admin_user).should look_like({
              :status => 200
            })
        end
      end

      context "outside user" do
        it "returns 403", :authorization, :smoke do
          delete(request_url, outside_user).should look_like({
              :status => 403
            })
          get(request_url, platform.admin_user).should look_like({
              :status => 200
            })
        end
      end

      context "invalid user" do
        it "returns 401", :authentication do
          delete(request_url, invalid_user).should look_like({
              :status => 401
            })
          get(request_url, platform.admin_user).should look_like({
              :status => 200
            })
        end
      end
    end # context DELETE /containers/<name>

    context "PUT /containers/<name>" do
      let(:new_container_payload) {{
        "containername" => test_container,
        "containerpath" => test_container
      }}

      let(:not_allowed_response) do
        if ruby?
          {:status => 404}
        else
          {
            :status => 405,
            :headers => {
              "allow" => ["GET, DELETE"]
            }
          }
        end
      end

      it "is not allowed" do
        put(request_url, platform.admin_user, :payload => new_container_payload)
          .should look_like(not_allowed_response)
      end
    end

    context "POST /containers/<name>" do

      let(:not_allowed_response) do
        if ruby?
          {:status => 404}
        else
          {
            :status => 405,
            :headers => {
              "allow" => ["GET, DELETE"]
            }
          }
        end
      end

      context "admin user" do
        # A 405 here would be fine (better, even)
        it "returns 404" do
          post(request_url, platform.admin_user).should look_like(not_allowed_response)
        end
      end
    end # context POST /containers/<name>
  end # context /containers/<name> endpoint
end # describe opscode-account container endpoint
