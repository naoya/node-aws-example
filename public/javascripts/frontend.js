(function() {
  $(function() {
    var preword, socket;
    $('img#loader').hide();
    $('#results a').live('click', function() {
      var item;
      location.href = '#asin';
      item = $(this).data('item');
      $('#asin h1').text(item.asin);
      $('#asin #content h2').text(item.title);
      return $('#asin #content img').attr('src', item.image);
    });
    socket = io.connect('http://localhost:3000');
    socket.on('items', function(items) {
      var item, json, ul, _i, _len;
      ul = $('#results');
      ul.children().remove();
      $('img#loader').hide();
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        json = JSON.stringify(item);
        ul.append("<li><a data-item='" + json + "'>" + item.title + "</a></li>");
      }
      return ul.listview('refresh');
    });
    preword = "";
    return setInterval(function() {
      var w;
      w = $('#search').val();
      if (w !== preword) {
        preword = w;
        $('img#loader').show();
        return socket.emit('query', w);
      }
    }, 2000);
  });
}).call(this);
