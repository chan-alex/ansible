#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and https://www.varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;
import std;

# Default backend definition. Set this to point to your content server.
backend default {
  .host = "127.0.0.1";
  .port = "9099";

  .first_byte_timeout     = 300s;   # How long to wait before we receive a first byte from our backend?
  .connect_timeout        = 60s;     # How long to wait for a backend connection?
  .between_bytes_timeout  = 30s;     # How long to wait between bytes received from our backend?
}

sub vcl_recv {
  # Happens before we check if we have this in cache already.
  #
  # Typically you clean up the request here, removing cookies you don't need,
  # rewriting the request, etc.

  # Only cache GET or HEAD requests. This makes sure the POST requests are always passed.
  if (req.method != "GET" && req.method != "HEAD") {
    return (pass);
  }

  if (req.http.Authorization) {
    # Not cacheable by default
    return (pass);
  }

  return(hash);
}

sub vcl_pipe {
  # Called upon entering pipe mode.
  # In this mode, the request is passed on to the backend, and any further data from both the client
  # and backend is passed on unaltered until either end closes the connection. Basically, Varnish will
  # degrade into a simple TCP proxy, shuffling bytes back and forth. For a connection in pipe mode,
  # no other VCL subroutine will ever get called after vcl_pipe.

  # Note that only the first request to the backend will have
  # X-Forwarded-For set.  If you use X-Forwarded-For and want to
  # have it set for all requests, make sure to have:
  set bereq.http.connection = "close";
  # here.  It is not set by default as it might break some broken web
  # applications, like IIS with NTLM authentication.

  # set bereq.http.Connection = "Close";

  return (pipe);
}

sub vcl_hash {
  hash_data(req.url);
  if (req.http.Locale == "zh" || 
      req.http.Locale == "zh_cn" || 
      req.http.Locale == "zh_tw" ||
      req.http.LOCALE == "zh" || 
      req.http.LOCALE == "zh_cn" || 
      req.http.LOCALE == "zh_tw") {
    hash_data("zh_tw");
  } else {
    hash_data(req.http.LOCALE);
    hash_data(req.http.Locale);
  }
  if (std.tolower(req.http.CLIENT) == "web" ||
      std.tolower(req.http.Client) == "web" || 
      std.tolower(req.http.CLIENT) == "ipad" ||
      std.tolower(req.http.Client) == "ipad") {
    hash_data("desktop");
  } else {
    hash_data("mobile");
  }
}

sub vcl_backend_response {
  # Happens after we have read the response headers from the backend.
  #
  # Here you clean the response headers, removing silly Set-Cookie headers
  # and other mistakes your backend does.

  unset beresp.http.Etag;
  unset beresp.http.Cache-Control;
  set beresp.http.Cache-Control = "public";

  if (beresp.http.Vary ~ "User-Agent") {
    set beresp.http.Vary = regsub(beresp.http.Vary, ",? User-Agent ", "");
    set beresp.http.Vary = regsub(beresp.http.Vary, "^, *", "");
    if (beresp.http.Vary == "") {
      unset beresp.http.Vary;
    }
  }

  if (beresp.status >= 500) {
    call safe_pass;
  }

  if (bereq.url ~ "^/beecrazy/api/v1/deals") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else if (bereq.url ~ "^/beecrazy/api/v1/categories") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else if (bereq.url ~ "^/beecrazy/api/v1/featured_events") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else if (bereq.url ~ "^/beecrazy/api/v1/marketing") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else if (bereq.url ~ "^/beecrazy/api/v1/site") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else if (bereq.url ~ "^/beecrazy/api/v1/flash_sales") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else if (bereq.url ~ "^/beecrazy/api/v1/deal_groupings") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else if (bereq.url ~ "^/beecrazy/api/v1/personas") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else if (bereq.url ~ "^/beecrazy/api/v1/search") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else if (bereq.url ~ "^/beecrazy/api/v1/deal_tags") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else if (bereq.url ~ "^/beecrazy/api/v1/mobile_ads") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else if (bereq.url ~ "^/beecrazy/api/v1/homepage_popups") {
    set beresp.ttl = 30m;
    set beresp.grace = 2d;
    return (deliver);
  } else {
    call safe_pass;
  }
  return(deliver);
}

sub vcl_deliver {
  # Happens when we have all the pieces we need, and are about to send the
  # response to the client.
  #
  # You can do accounting or modifying the final object here.
  if (obj.hits > 0) {
    set resp.http.X-Cache ="HIT";
  } else {
    set resp.http.X-Cache = "MISS";
  }
  # Please note that obj.hits behaviour changed in 4.0, now it counts per objecthead, not per object
  # and obj.hits may not be reset in some cases where bans are in use. See bug 1492 for details.
  # So take hits with a grain of salt
  set resp.http.X-Cache-Hits = obj.hits;

  set resp.http.Access-Control-Allow-Origin = "*";

  return(deliver);
}

sub vcl_hit {
  if (obj.ttl >= 0s) {
    # A pure unadultered hit, deliver it
    return (deliver);
  }
  if (obj.ttl + obj.grace > 0s) {
    # Object is in grace, deliver it
    # Automatically triggers a background fetch
    return (deliver);
  }
  # fetch & deliver once we get the result
  return (fetch);
}

sub safe_pass {
  set beresp.uncacheable = true;
  set beresp.ttl = 2s;
  return (deliver);
}
