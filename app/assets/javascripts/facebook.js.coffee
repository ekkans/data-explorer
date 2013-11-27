jQuery ->
  $('body').prepend('<div id="fb-root"></div>')

  $.ajax
    url: "#{window.location.protocol}//connect.facebook.net/en_US/all.js"
    dataType: 'script'
    cache: true

window.fbAsyncInit = ->
  resetUI()
  initEventHandlers()
  FB.init(appId: $('body').data('facebook-app-id'), cookie: true)
  FB.getLoginStatus (response) =>
    if response.status is 'connected'
      showActions()

window.resetUI = ->
  $('#facebook .content').html("<button type='button' class='sign-in sign-in btn btn-primary btn-lg'>Connect</button>")

window.initEventHandlers = ->
  $('#facebook')
    .on 'click', '.sign-in', (e) ->
      e.preventDefault()
      FB.login (response) ->
        if response.authResponse
          showActions()
      , { scope: 'user_groups, user_location, friends_location' }
        
    .on 'click', '.sign-out', (e) ->
      e.preventDefault()
      FB.getLoginStatus (response) ->
        FB.logout() if response.authResponse
        resetUI()
      true

window.showActions = ->
  FB.api '/me', (response) =>
    $('#facebook .content')
      .html("<a href='#' class='pull-right sign-out'>Sign out</a>")
      .append("<h3>Welcome #{response.name}</h3>")
      .append("<hr/>")
      .append("<div class='groups-section'><button type='button' class='see-my-groups btn btn-primary'>See my groups</a></div>")

  $('#facebook')
    .on 'click', '.see-my-groups', (e) ->
      e.preventDefault()
      FB.api "/me/groups", (resp) ->
        groupsData = resp.data
        if resp.data.length > 0
          target = $("#facebook .groups-section")
          $(target).html('<h4>My groups</h4>')
          $(target).append('<ol>')
          for group in resp.data
            $(target).append("<li><a href='#' class='group' data-id='#{group.id}' data-name='#{group.name}'>#{group.name}</a></li>")
          $(target).append('</ol>')
          
    .on 'click', '.group', (e) ->
      e.preventDefault()
      groupId = $(e.currentTarget).data('id')
      groupName = $(e.currentTarget).data('name')
      target = $("#facebook .groups-section")
      $(target).html("<h4>Group: #{groupName}</h4>")
      $(target).append("<hr/>")
      FB.api "/#{groupId}/members", (resp) ->
        membersData = [] # resp.data
        membersDataLength = resp.data.length
        $(target).append("<h4 class='members'>Members</h4>")
        $(target).append('<table class="table table-striped table-hover table-responsive"></table>')
        $(target).find('table').append('<thead><tr><th>#</th><th>Name</th><th>Location</th></tr></thead>')
        $(target).find('table').append('<tbody></tbody>')
        for member, index in resp.data
          $(target).find('tbody').append("<tr class='member' data-id='#{member.id}'><td>#{index + 1}</td>
            <td class='name'></td><td class='location'></td></tr>")
          FB.api "/#{member.id}", (resp) ->
            member = resp
            membersData.push(member)
            if resp.location
              locationId = resp.location['id']
              locationName = resp.location['name']
            $(target).find(".member[data-id='#{member.id}']")
              .find('.name').html(member.name)
              .parents('tr')
              .find('.location').html(if locationName? then locationName else "")
            if membersData.length is membersDataLength
              # Ability to copy names and locations to clipboard
              $(target)
                .find('.members')
                .before("<ul class='pull-right list-inline'></ul>")
                .parents('.groups-section').find('ul')
                .append("<li><a href='#' class='pull-right export zero-clipboard'>Copy data</a></li>")
              names = ""
              locations = ""
              for member in membersData
                names += member.name + "\r\n"
                if member.location? and locations.indexOf(member.location.name) is -1
                  locations += member.location.name + "\r\n"
              clip = new ZeroClipboard()
              clip.glue($(".zero-clipboard"))
              clip.on "dataRequested", (client, args) ->
                clip.setText("#{names}\r\n#{locations}")
              clip.on "complete", (client, text) ->
                alert "Text copied to clipboard."
