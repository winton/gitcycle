class Gitcycle
  module Incident

    def incident(*args)
      puts "\nRetrieving statuspage.io information from gitcycle.\n".green
      
      statuspage = get('statuspage')
      components = statuspage['components']
      incidents  = statuspage['incidents']
      page       = statuspage['page']
      
      incident_statuses  = %w(investigating identified monitoring resolved)
      incident_colors    = %w(red           yellow     yellow     green)
      
      component_statuses = %w(operational degraded_performance partial_outage major_outage)
      component_colors   = %w(green       yellow               yellow         red)

      puts_statuses(incidents, incident_statuses, incident_colors)

      incident = q "\n#{"Incident #?".yellow} (press enter for new incident)"

      if incident.strip == ""
        incident     = {}
        new_incident = q "#{"New incident name?".yellow} (required)"
      else
        incident = incidents[incident.to_i]
      end

      unless incident['id'] || new_incident
        puts "Incident not found."
        exit
      end

      puts_statuses(components, component_statuses, component_colors)

      component = q "\n#{"Service #?".yellow} (required)"
      component = components[component.to_i]

      unless component
        puts "Service not found."
        exit
      end

      puts_names(component_statuses, component_colors)

      component_status = q "\n#{"Service status #?".yellow} (required)"
      puts_names(incident_statuses, incident_colors)

      incident_status = q "\n#{"Incident status #?".yellow} (required)"
      incident_body   = q "\n#{"Describe the incident".yellow} (enter for none)"

      component_status = component_statuses[component_status.to_i]
      incident_status  = incident_statuses[incident_status.to_i]

      unless component_status
        puts "Component status not found."
        exit
      end

      unless incident_status
        puts "Incident status not found."
        exit
      end

      params = {
        :new_incident     => new_incident,
        :incident         => incident['id'],
        :component        => component['id'],
        :component_status => component_status,
        :incident_status  => incident_status,
        :incident_body    => incident_body
      }

      puts "\nUpdating statuspage.io...".green
      get('statuspage/update', params)

      puts "\nSuccess!\n".green

      sleep 0.5
      Launchy.open("http://#{page['subdomain']}.statuspage.io")
    end

    private

    def format_name(name)
      name.gsub(/_/, ' ').capitalize
    end

    def longest_name(array)
      array.map { |a| a['name'].length }.max
    end

    def puts_names(array, colors)
      puts ""

      array.each_with_index do |a, i|
        puts "[#{i}] #{format_name(a).send(colors[i])}"
      end
    end

    def puts_statuses(array, statuses, colors)
      longest = longest_name(array)
      puts ""

      array.each_with_index do |a, i|
        name   = a['name']
        status = a['status']
        status = format_name(status).send(colors[statuses.index(status)])

        puts "[#{i}] #{name} #{" " * (longest - name.length)} #{status}"
      end
    end
  end
end