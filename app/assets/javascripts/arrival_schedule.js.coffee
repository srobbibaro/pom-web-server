$(document).ready () ->
  return unless $.find('#map-section').length > 0
  locations = []
  recipients = []
  location_checks = []
  marker    = null
  circle    = null

  # TODO: Do this in a smarter way
  testMode = $('#test').length > 0

  # Temporary - these coordinates are essentially the mid point of the United States
  current_pos = {latitude: 40.44183, longitude: -80.01278, range: 50.0}

  $('#recipient_mobile').mask("(999) 999-9999")

  map = new google.maps.Map($(".location-map-canvas").get(0), {
    zoom:        18,
    mapTypeId:   google.maps.MapTypeId.HYBRID,
    center:      {lat: current_pos.latitude, lng: current_pos.longitude},
    tilt:        0,
    scrollwheel: false
  })

  $("input[name='notify_method']").on 'click', () ->
    if $(this).val() == "email"
      $('.notify-mobile').parent().hide()
      $('.notify-email').parent().show()
    else
      $('.notify-mobile').parent().show()
      $('.notify-email').parent().hide()

  $('.recipient-button').on 'click', () ->
    previous_id = $(this).parent().find('.active').attr('data-id')
    new_id      = $(this).attr('data-id')

    updateStoredRecipientFromFields(previous_id)
    updateRecipientSettings(new_id)

  $('#save').on 'click', () ->
    name = $('#name').val()
    current_pos.longitude = marker.getPosition().lng()
    current_pos.latitude = marker.getPosition().lat()

    if !name
      displayAlert("You must enter a location name.", 'danger')
    else if !current_pos.longitude or !current_pos.latitude
      $('.location').html("Invalid location")
      displayAlert("Could not save invalid location", 'danger')
    else
      selected = $('.saved-locations > table > tbody').find('.selected')
      id = if selected.length > 0 then selected.parent().attr('data-id') else null

      recipient_id = $('.recipient-button.active').first().attr('data-id')
      updateStoredRecipientFromFields(recipient_id)

      $.ajax {
        type: 'POST',
        url: '/arrival_schedule/schedule',
        contentType: "application/json",
        data: JSON.stringify({
          arrival_schedule: {
            longitude:  current_pos.longitude,
            latitude:   current_pos.latitude,
            range:      circle.getRadius(),
            name:       name,
            id:         id,
            active:     $('input[name=active]:checked').val(),
            recipients: recipients
          }
        }),
        success: (data) ->
          if data.result
            addLocation(data)
            data.marker = addMarker(data, map)
            data.circle = addBoundingCircle(data, map)
            locations.push(data)
            clickFirst()
            displayAlert(data.message)
          else
            displayAlert(data.message, 'danger')
      }

  $('#fetch').on 'click', () ->
    success = (position) ->
      updateLocation({
        latitude:  position.coords.latitude,
        longitude: position.coords.longitude,
      })

    error = (err) ->
      $('.location').html("Could not load location (#{err.code}): #{err.message}")

    if navigator.geolocation
      $('.location').html("Loading...")

      navigator.geolocation.getCurrentPosition(success, error, {
        enableHighAccuracy: true,
        timeout:            20000,
        maximumAge:         0
      })
    else
      $('.location').html("Feature not supported")

  $('#fetch_location_checks').on 'click', () ->
    fetchLocationChecks()

  $('[data-hide]').on 'click', () ->
    $('.alert').hide()

  searchBox = new google.maps.places.SearchBox($('#search_text').get(0))

  map.addListener('bounds_changed', () ->
    searchBox.setBounds(map.getBounds())
  )

  searchBox.addListener('places_changed', () ->
    places = searchBox.getPlaces()

    return if places.length == 0

    $('.location').html("Loading...")

    updateLocation({
      name:      places[0].name,
      latitude:  places[0].geometry.location.lat(),
      longitude: places[0].geometry.location.lng()
    })
  )

  $('#test').on 'click', () ->
    current_pos.longitude = marker.getPosition().lng()
    current_pos.latitude = marker.getPosition().lat()

    if !current_pos.longitude or !current_pos.latitude
      $('.location').html("Invalid location")
      displayAlert("Could not test invalid location", 'danger')
    else
      $.ajax {
        type: 'POST',
        url: '/arrival_schedule/check_location',
        data: {
          longitude: current_pos.longitude,
          latitude:  current_pos.latitude
        },
        success: (data) ->
          message = "Matched (#{data.length}) locations."
          if data.length > 0
            message = message + "\n\n" + _.map(data, (n) -> "#{n.notification.full}").join('\n')
          displayAlert(message)
      }

  selectLocationHandler = () ->
    id = $(this).parent().attr('data-id')
    updateLocation(_.find(locations, (l) -> "#{l.id}" == "#{id}"))
    _.each(locations, (l) -> l.marker.setOpacity(if "#{l.id}" != "#{id}" then 1.0 else .4))
    $(this).addClass('selected')

  removeLocationHandler = () ->
    id = $(this).parent().attr('data-id')
    $('#delete_location_confirm').on 'click', () ->
      $('#delete_location_modal').modal('hide')
      if id
        $.ajax {
          type: 'POST',
          url: '/arrival_schedule/remove_schedule',
          data: {
            id: id
          },
          success: (data) ->
            if data and data.result
              removeLocation(id)
              locations = _.reject(locations, (l) -> "#{l.id}" == "#{id}")
              if locations.length == 0
                $('.saved-locations').css('display', 'none')
                $('.no-saved-locations').css('display', 'block')
                updateLocationSettings()
              else
                clickFirst()
        }
    $('#delete_location_modal').modal('show')

  findIpBasedLocation = () ->
    $('.location').html("Loading...")
    $.ajax {
      type: 'POST',
      url: '/location_check/find_location',
      success: (data) ->
        if data && data.longitude && data.latitude
          updateLocation({
            latitude:  data.latitude,
            longitude: data.longitude,
          })
        else
          $('.location').html("Location: Default")
      error: (err) ->
        $('.location').html("Could not load location (#{err.code}): #{err.message}")
    }

  updateLocation = (arrival) ->
    $('.saved-location').removeClass('selected')
    if arrival
      current_pos.latitude  = arrival.latitude
      current_pos.longitude = arrival.longitude

      $('.location').html(if arrival.name then "Location: #{arrival.name}" else "Your current position")

      pos = new google.maps.LatLng(current_pos.latitude, current_pos.longitude)
      map.setCenter(pos)
      marker.setPosition(pos)

      circle.setRadius(arrival.range)

      updateLocationSettings(arrival)
    else
      $('.location').html("Invalid location")

  clickFirst = () ->
    if ('.saved-location').length > 0
      $('.saved-location').first().click()

  updateLocationSettings = (arrival={}) ->
    active = if arrival.active then arrival.active else 0
    name   = if arrival.name then arrival.name else ''

    $('#name').val(name)
    $("#active_#{active}").prop('checked', true)

    recipients = $.extend(true, [], arrival.recipients)
    _.each([recipients.length..4], (i) -> recipients.push({}))

    updateRecipientSettings(1)

  updateRecipientSettings = (recipient_num) ->
    recipient = recipients[recipient_num - 1]
    notification_method = if recipient?.notification_method then recipient.notification_method else "email"
    mobile_carrier      = if recipient?.mobile_carrier then recipient.mobile_carrier else "Select a Carrier"
    email_address       = if recipient?.email_address then recipient.email_address else ''
    mobile_number       = if recipient?.mobile_number then recipient.mobile_number else ''

    $('#recipient_email').val(email_address)
    $('#recipient_mobile').val(mobile_number)
    $("#notify_method_#{notification_method}").click()
    $('#mobile_carrier').val(mobile_carrier)

    $(".recipient-button").removeClass('active')
    $("#recipient-#{recipient_num}").addClass('active')

  updateStoredRecipientFromFields = (recipient_num) ->
    recipients[recipient_num - 1] = {
      email_address:       $('#recipient_email').val(),
      mobile_number:       $('#recipient_mobile').val().replace(/[^\d]/g, ''),
      mobile_carrier:      $('#mobile_carrier').val(),
      notification_method: $('input[name=notify_method]:checked').val()
    }

  addLocation = (data) ->
    removeLocation(data.id)
    locations = _.reject(locations, (l) -> "#{l.id}" == "#{data.id}")
    $('.saved-locations > table > tbody:first').prepend( "<tr data-id=\"#{data.id}\">" +
      "<td class=\"location-table-cell-fixed saved-location\">#{data.name}</td>" +
      "<td>#{if locationActive(data) then 'yes' else 'no'}</td>" +
      "<td class=\"remove-location\">" +
      "<img src=\"/delete.png\" alt=\"Remove this location\" title=\"Remove this location\" height=\"16\" width=\"16\"/></td>" +
      "</tr>"
    )

    $('.saved-locations').css('display', 'block')
    $('.no-saved-locations').css('display', 'none')

    $('.saved-location').first().on 'click', selectLocationHandler
    $('.remove-location').first().on 'click', removeLocationHandler

  removeLocation = (id) ->
    selected_location = _.find(locations, (l) -> "#{l.id}" == "#{id}")
    selected_location.marker.setMap(null) if selected_location
    selected_location.circle.setMap(null) if selected_location
    $("[data-id='#{id}']").remove()

  addBoundingCircle = (location, map, color=null, editable=false) ->
    unless color
      color = if locationActive(location) then '#0000FF' else '#FF0000'

    opacity = 0.05
    strokeOpacity = 0.8

    new google.maps.Circle({
      strokeColor:   color,
      strokeOpacity: strokeOpacity,
      strokeWeight:  2,
      fillColor:     color
      fillOpacity:   opacity,
      map:           map,
      radius:        location.range,
      center:        {lat: location.latitude, lng: location.longitude},
      editable:      editable,
      visible:       !markersHidden && (!testMode || !editable)
    })

  addMarker = (location, map, draggable=false) ->
    determineMarkerColor = ->
      if draggable
        'green'
      else if locationActive(location)
        'blue'
      else
        'red'

    new google.maps.Marker({
      position:  {lat: location.latitude, lng: location.longitude},
      map:       map,
      draggable: draggable
      title:     if draggable then "Drag to location" else "Location: #{location.name} (#{if locationActive(location) then "enabled" else "disabled"})",
      opacity: 1.0,
      icon: {
        url:        "/pom_marker_#{determineMarkerColor()}.png"
        scaledSize: new google.maps.Size(50, 50)
        anchor:     new google.maps.Point(18, 50),
      }
    })

  addCircleMarker = (location, map) ->
    new google.maps.Marker({
      position: {lat: location.latitude, lng: location.longitude},
      map:      map
      title:    "Latitude: #{location.latitude}\nLongitude: #{location.longitude}\n" +
                "Date: #{location.date}\n" +
                "Test: #{location.test}\n" +
                "Matches: #{if location.matches.length > 0 then location.matches else "None"}\n"
    })

  locationActive = (location) ->
    location.active == "1"

  fetchLocations = () ->
    $.ajax {
      type: 'POST',
      url: '/arrival_schedule/locations',
      success: (data) ->
        if data
          locations = _.map(data.reverse(), (d) ->
            addLocation(d)
            add_marker = addMarker(d, map)
            add_circle = addBoundingCircle(d, map)
            $.extend({}, d, {marker: add_marker, circle: add_circle})
          )
          if locations.length > 0
            clickFirst()
          else
            findIpBasedLocation()
    }

  updateLocationCheckHandler = () ->
    id = $(this).attr('data-id')
    location_check = _.find(location_checks, (l) -> "#{l.id}" == "#{id}")
    if location_check
      current_pos.latitude  = location_check.latitude
      current_pos.longitude = location_check.longitude

      $('.location').html(if location_check.id then "Location: #{location_check.id}" else "Your current position")

      pos = new google.maps.LatLng(current_pos.latitude, current_pos.longitude)
      map.setCenter(pos)
      marker.setPosition(pos)
    else
      $('.location').html("Invalid location")
    $('html, body').animate({ scrollTop: 0})

  fetchLocationChecks = () ->
    $.ajax {
      type: 'POST',
      url: '/location_check/location_checks',
      data: {
        limit: $('#location_check_limit').val()
      },
      success: (data) ->
        if data
          _.each(location_checks, (check) ->
            check.marker.setMap(null)
          )
          location_checks = _.map(data, (d) ->
            if d.longitude and d.latitude
              add_marker = addCircleMarker(d, map)
              $.extend({}, d, {marker: add_marker, date: new Date(d.date).toLocaleString()})
            else
              null
          )
          _.compact(location_checks)
          $('.recent-checks tbody').empty()
          _.each(location_checks, (check) ->
            $('.recent-checks > table > tbody:first').prepend( "<tr data-id=\"#{check.id}\">" +
              "<td>#{check.id}</td>" +
              "<td>#{check.longitude}</td>" +
              "<td>#{check.latitude}</td>" +
              "<td>#{check.date}</td>" +
              "<td>#{check.matches}</td>" +
              "<td>#{check.test}</td>" +
              "</tr>"
            )
          )
          $('.recent-checks tr').on 'click', updateLocationCheckHandler
    }

  displayAlert = (text, alert_class='success') ->
    alert_bar = $('.alert')
    alert_bar.removeClass("alert-danger alert-success")
    alert_bar.addClass("alert-#{alert_class}")
    alert_bar.find('.text').first().html(text)
    $(".alert").show()
    $('html, body').animate({ scrollTop: alert_bar.offset().top - 20})

  $('#notify_method_email').click()

  # Ensure that the map is is proper width -- scale it manually
  setMapWidth()

  markersHidden = true
  if testMode || window.location.search.slice(1) == "radius=1"
    markersHidden = false

  marker = addMarker(current_pos, map, true)
  circle = addBoundingCircle(current_pos, map, '#00FF00', true)
  circle.bindTo('center', marker, 'position')

  google.maps.event.addListener(map, "click", (event) ->
    marker.setPosition(event.latLng)
  )

  fetchLocations()

  if testMode
    $('#location_check_limit').val(100)
    fetchLocationChecks()

setMapWidth = () ->
  return unless $.find('#map-section').length > 0
  width = $('#map-section').width()
  $('.location-map').css({width: width})

$(window).resize () ->
  setMapWidth()
