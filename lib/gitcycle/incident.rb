class Gitcycle
  module Incident

    def incident(*args)
      puts "\nRetrieving statuspage.io information from gitcycle.\n".green
      
      statuspage = get('statuspage')
      incidents  = statuspage['incidents']
      
      incident_statuses = %w(investigating identified monitoring resolved)
      incident_colors   = %w(red           yellow     yellow     green)

      puts_statuses(incidents, incident_statuses, incident_colors)

      incident = q "\n#{"Incident #?".yellow} (press enter for new incident)"

      if incident.strip == ""
        incident = q "\n#{"New incident name?".yellow} (required)"
      else
        incident = incident[incident.to_i]
      end

      components         = statuspage['components']
      component_statuses = %w(operational degraded_performance partial_outage major_outage)
      component_colors   = %w(green       yellow               yellow         red)
      
      puts_statuses(components, component_statuses, component_colors)

      component = q "\n#{"Service #?".yellow} (required)"
      puts_names(component_statuses)

      component_status = q "\n#{"Service status #?".yellow} (required)"
      puts_names(incident_statuses)

      incident_status = q "\n#{"Incident status #?".yellow} (required)"
      incident_body   = q "\n#{"Describe the incident".yellow} (enter for none)"
    end

    private

    def format_name(name)
      name.gsub(/_/, ' ').capitalize
    end

    def longest_name(array)
      array.map { |a| a['name'].length }.max
    end

    def puts_names(array)
      puts ""

      array.each_with_index do |a, i|
        puts "[#{i}] #{format_name(a)}"
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