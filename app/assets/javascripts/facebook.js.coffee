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
        $(target).append("<h4>Members</h4>")
        $(target).append('<ol>')
        $(target).append('</ol>')
        for member in resp.data
          FB.api "/#{member.id}", (resp) ->
            member = resp
            if resp.location
              locationId = resp.location['id']
              locationName = resp.location['name']
            $(target).find('ol').append("<li><a href='#' class='member' data-id='#{member.id}'
              data-name='#{member.name}'>#{member.name}#{if locationName? then " - #{locationName}" else ""}</a></li>")