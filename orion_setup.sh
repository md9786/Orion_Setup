http:
  pprof:
    port: 6060
    enabled: false
  address: 0.0.0.0:4200
  session_ttl: 720h
users:
  - name: $AGH_USERNAME
    password: $AGH_PASSWORD_HASH
auth_attempts: 5
block_auth_min: 15
http_proxy: ""
language: en
theme: auto
dns:
  bind_hosts:
    - 0.0.0.0
  port: 53
  anonymize_client_ip: false
  ratelimit: 0
  ratelimit_subnet_len_ipv4: 24
  ratelimit_subnet_len_ipv6: 56
  ratelimit_whitelist: []
  refuse_any: true
  upstream_dns:
    - https://dns.cloudflare.com/dns-query
    - https://dns.google/dns-query
    - 2001:4860:4860::8888
    - 2001:4860:4860::8844
    - https://dns.quad9.net/dns-query
  upstream_dns_file: ""
  bootstrap_dns:
    - 9.9.9.9
    - 149.112.112.112
    - 2620:fe::fe
    - 2620:fe::9
  fallback_dns:
    - 1.1.1.1
    - 8.8.8.8
    - 8.8.4.4
    - 9.9.9.9
  upstream_mode: parallel
  fastest_timeout: 1s
  allowed_clients:
    - 127.0.0.1
    - 77.110.110.251
  disallowed_clients:
    - 47.237.111.86
    - 193.163.125.41
    - 87.236.176.141
    - 43.133.115.188
    - 2001:550:9005:e000::11
  blocked_hosts:
    - a.applovin.com
    - a.applvn.com
    - ad.mail.ru
    - adsassets.waze.com
    - ads-resources.waze.com
    - af.opera.com
    - api.ad.intl.xiaomi.com
    - api.appcues.net
    - api.bidmachine.io
    - api.gameanalytics.com
    - api.mossturbo.com
    - api.rqmob.com
    - api.tradplusad.com
    - api16-access-ttp.tiktokpangle.us
    - api2.amplitude.com
    - api3.branch.io
    - api-apac.bidmachine.io
    - api-js.mixpanel.com
    - api-sdk.datadome.co
    - app-analytics-services.com
    - app-analytics-services-att.com
    - app-analytics-v2.snapchat.com
    - app-measurement.com
    - appsgrowthpromo-pa.googleapis.com
    - auth.split.io
    - aws.inshot.cc
    - beacons.gcp.gvt2.com
    - beacons.gvt2.com
    - beacons5.gvt3.com
    - bstream.kzhi.tech
    - ca.iadsdk.apple.com
    - cdn.cookielaw.org
    - cdn.iads.unity3d.com
    - cdn2.inner-active.mobi
    - collect.ureca-lab.com
    - collector.superwall.me
    - config.inmobi.com
    - csi.gstatic.com
    - csp.withgoogle.com
    - dc.dqa.samsung.com
    - delivery-cdn-cf.adswizz.com
    - diagmon-serviceapi.samsungdm.com
    - directaccessshield.top
    - dit.whatsapp.net
    - dt.beyla.site
    - ehwgjk.fingerhi.net
    - ep2.facebook.com
    - etahub.com
    - event.tradplusad.com
    - events.mapbox.com
    - federatedcompute-pa.googleapis.com
    - firebaselogging.googleapis.com
    - firebaselogging-pa.googleapis.com
    - firebase-settings.crashlytics.com
    - g.live.com
    - gamedot.afafb.com
    - googleads.g.doubleclick.net
    - graph.instagram.com
    - growth-pa.googleapis.com
    - grs.dbankcloud.asia
    - grs.dbankcloud.cn
    - grs.dbankcloud.com
    - grs.dbankcloud.eu
    - hansha.online
    - hehw.fingerhi.net
    - hostname.bind
    - id.server
    - in.appcenter.ms
    - izirx.fingerhi.net
    - jarlio.launches.appsflyersdk.com
    - jarlio-inapps.appsflyersdk.com
    - jarlio-launches.appsflyersdk.com
    - ke-izirx.fingerhi.net
    - kw3qbu.launches.appsflyersdk.com
    - locationhistory-pa.googleapis.com
    - log16-normal-useast8.tiktokv.us
    - logs.ads.vungle.com
    - mc.yandex.com
    - mcc-intl.inf.miui.com
    - mcds.dalyfeds.com
    - mediation-sg2-log.pangle.io
    - mobile.events.data.microsoft.com
    - mobile.pipe.aria.microsoft.com
    - mqtt-gw.pushnotifs.com
    - mqtt-mini.facebook.com
    - ms.applovin.com
    - ms.applvn.com
    - notifications-ueeshp-pa.googleapis.com
    - o4505708692307968.ingest.us.sentry.io
    - oqz9c1.launches.appsflyersdk.com
    - o-sdk.mediation.unity3d.com
    - pagead2.googlesyndication.com
    - perseus-productanalytics.deliveryhero.net
    - privacy-sandbox.appsflyersdk.com
    - prod-mediate-events.applovin.com
    - pubads.g.doubleclick.net
    - pushstat.api.engagelab.cc
    - receiver.habby.mobi
    - region1.app-analytics-services.com
    - region1.app-analytics-services-att.com
    - region1.app-measurement.com
    - report.appmetrica.yandex.net
    - reporting-eu.deliveryengine.adswizz.com
    - reqhfg-launches.appsflyersdk.com
    - rt.applovin.com
    - rygxvs.skadsdkless.appsflyersdk.com
    - sac.presage.io
    - scar.unityads.unity3d.com
    - sdk.iad-01.braze.com
    - sdk.split.io
    - sdk-04.moengage.com
    - sdkapi.dsp-api.moloco.com
    - sdk-api-v1.singular.net
    - sdkconfig.ad.intl.xiaomi.com
    - sdk-events.inner-active.mobi
    - searchlabspartnerservice-pa.googleapis.com
    - self.events.data.microsoft.com
    - shareit-push-cdn.wshareit.com
    - spadsync.com
    - startup.mobile.yandex.net
    - static.trafficjunky.com
    - t.appsflyer.com
    - teams.events.data.microsoft.com
    - telemetry.sdk.inmobi.com
    - tpc.googlesyndication.com
    - tracking.intl.miui.com
    - trk.pinterest.com
    - udm.scorecardresearch.com
    - unif-id.ssp.inmobi.com
    - ureca.samsungapps.com
    - user-content.superwalleditor.com
    - version.bind
    - vortex.data.microsoft.com
    - www.googletagmanager.com
    - www.googletagservices.com
    - www.pullcf.com
    - www.pullcm.com
    - x.everestop.io
    - xgapromomanager-pa.googleapis.com
    - y.hashemi0026.example.com
    - y.hashemi0026.example.com.aeza.network
  trusted_proxies:
    - 127.0.0.0/8
    - ::1/128
  cache_enabled: true
  cache_size: 4194304
  cache_ttl_min: 0
  cache_ttl_max: 0
  cache_optimistic: false
  cache_optimistic_answer_ttl: 30s
  cache_optimistic_max_age: 12h
  bogus_nxdomain: []
  aaaa_disabled: false
  enable_dnssec: true
  edns_client_subnet:
    custom_ip: ""
    enabled: false
    use_custom: false
  max_goroutines: 300
  handle_ddr: true
  ipset: []
  ipset_file: ""
  bootstrap_prefer_ipv6: false
  upstream_timeout: 10s
  private_networks: []
  use_private_ptr_resolvers: true
  local_ptr_upstreams: []
  use_dns64: false
  dns64_prefixes: []
  serve_http3: false
  use_http3_upstreams: false
  serve_plain_dns: true
  hostsfile_enabled: true
  pending_requests:
    enabled: true
tls:
  enabled: true
  server_name: $DOMAIN
  force_https: true
  port_https: 2053
  port_dns_over_tls: 853
  port_dns_over_quic: 853
  port_dnscrypt: 0
  dnscrypt_config_file: ""
  allow_unencrypted_doh: false
  certificate_chain: ""
  private_key: ""
  certificate_path: /root/cert/$DOMAIN/fullchain.pem
  private_key_path: /root/cert/$DOMAIN/privkey.pem
  strict_sni_check: false
querylog:
  dir_path: ""
  ignored: []
  interval: 24h
  size_memory: 1000
  enabled: true
  ignored_enabled: false
  file_enabled: true
statistics:
  dir_path: ""
  ignored: []
  interval: 24h
  enabled: true
  ignored_enabled: false
filters:
  - enabled: true
    url: https://hblock.molinero.dev/hosts
    name: hblock
    id: 1744973154
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
    name: AdGuard DNS filter
    id: 1744973155
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_53.txt
    name: AWAvenue Ads Rule
    id: 1744973156
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_51.txt
    name: HaGeZi's Pro++ Blocklist
    id: 1744973158
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt
    name: Dandelion Sprout's Anti-Malware List
    id: 1744973160
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt
    name: Phishing URL Blocklist (PhishTank and OpenPhish)
    id: 1744973161
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_19.txt
    name: 'IRN: PersianBlocker list'
    id: 1744973162
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt
    name: Perflyst and Dandelion Sprout's Smart-TV Blocklist
    id: 1744973163
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_4.txt
    name: Dan Pollock's List
    id: 1744973166
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt
    name: Scam Blocklist by DurableNapkin
    id: 1744973169
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt
    name: Phishing Army
    id: 1744973170
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_54.txt
    name: HaGeZi's DynDNS Blocklist
    id: 1744973174
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt
    name: Malicious URL Blocklist (URLHaus)
    id: 1744973175
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt
    name: Steven Black's List
    id: 1744973179
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt
    name: Peter Lowe's Blocklist
    id: 1744973180
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt
    name: OISD Blocklist Big
    id: 1744973181
whitelist_filters:
  - enabled: true
    url: https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/whitelist-urlshortener.txt
    name: Url Shortner
    id: 1743772236
user_rules:
  - '@@||orionnexus.top^'
  - '@@||Mpic.php^'
  - '@@||soundcloud.com^'
  - '@@||avamovie.shop^'
  - '@@||ccb.megafiles.store^'
  - '@@||icyhailstorm29.online^'
  - '@@||clearbluesky72.wiki^'
  - '@@||notube.cc^'
  - '@@||directaccessshield.top^'
  - '!------------------------------------'
  - '||easybrain.com^'
  - '||adservice.google.*^'
  - '||adsterra.com^'
  - '||amplitude.com^'
  - '||analytics.edgekey.net^'
  - '||analytics.twitter.com^'
  - '||app.adjust.*^'
  - '||app.*.adjust.com^'
  - '||app.appsflyer.com^'
  - '||doubleclick.net^'
  - '||googleadservices.com^'
  - '||guce.advertising.com^'
  - '||metric.gstatic.com^'
  - '||mmstat.com^'
  - '||statcounter.com^'
  - '||y.hashemi0026.example.com.aeza.network^'
  - '||y.hashemi0026.example.com^'
  - ""
dhcp:
  enabled: false
  interface_name: ""
  local_domain_name: lan
  dhcpv4:
    gateway_ip: ""
    subnet_mask: ""
    range_start: ""
    range_end: ""
    lease_duration: 86400
    icmp_timeout_msec: 1000
    options: []
  dhcpv6:
    range_start: ""
    lease_duration: 86400
    ra_slaac_only: false
    ra_allow_slaac: false
filtering:
  blocking_ipv4: ""
  blocking_ipv6: ""
  blocked_services:
    schedule:
      time_zone: Local
    ids: []
  protection_disabled_until: null
  safe_search:
    enabled: false
    bing: true
    duckduckgo: true
    ecosia: true
    google: true
    pixabay: true
    yandex: true
    youtube: true
  blocking_mode: default
  parental_block_host: family-block.dns.adguard.com
  safebrowsing_block_host: standard-block.dns.adguard.com
  rewrites: []
  safe_fs_patterns:
    - /opt/AdGuardHome/userfilters/*
  safebrowsing_cache_size: 1048576
  safesearch_cache_size: 1048576
  parental_cache_size: 1048576
  cache_time: 30
  filters_update_interval: 72
  blocked_response_ttl: 10
  filtering_enabled: true
  rewrites_enabled: true
  parental_enabled: false
  safebrowsing_enabled: false
  protection_enabled: true
clients:
  runtime_sources:
    whois: true
    arp: true
    rdns: true
    dhcp: true
    hosts: true
  persistent:
    - safe_search:
        enabled: false
        bing: true
        duckduckgo: true
        ecosia: true
        google: true
        pixabay: true
        yandex: true
        youtube: true
      blocked_services:
        schedule:
          time_zone: Local
        ids: []
      name: AEZA
      ids:
        - 127.0.0.1
      tags: []
      upstreams: []
      uid: 01962f1a-bd38-7843-82e8-94fcb36b2a31
      upstreams_cache_size: 0
      upstreams_cache_enabled: false
      use_global_settings: true
      filtering_enabled: false
      parental_enabled: false
      safebrowsing_enabled: false
      use_global_blocked_services: true
      ignore_querylog: false
      ignore_statistics: false
    - safe_search:
        enabled: false
        bing: true
        duckduckgo: true
        ecosia: true
        google: true
        pixabay: true
        yandex: true
        youtube: true
      blocked_services:
        schedule:
          time_zone: Local
        ids: []
      name: Abramad
      ids:
        - 92.61.182.163
      tags: []
      upstreams:
        - 1.1.1.1
        - 1.0.0.1
        - 8.8.8.8
        - 8.8.4.4
        - 9.9.9.9
      uid: 01960176-09d0-74f3-a890-df7f2f00960b
      upstreams_cache_size: 0
      upstreams_cache_enabled: false
      use_global_settings: true
      filtering_enabled: false
      parental_enabled: false
      safebrowsing_enabled: false
      use_global_blocked_services: true
      ignore_querylog: false
      ignore_statistics: false
log:
  enabled: true
  file: ""
  max_backups: 0
  max_size: 100
  max_age: 3
  compress: false
  local_time: false
  verbose: false
os:
  group: ""
  user: ""
  rlimit_nofile: 0
schema_version: 33
