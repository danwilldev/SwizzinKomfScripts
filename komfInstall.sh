#!/bin/bash

# Script by @meguXmeme
# For Komf Install
install() {
    user=$(_get_master_username)
    echo_progress_start "Making data directory and owning it to ${user}"
    mkdir -p "/opt/komf"
    echo_progress_done "Data Directory created and owned."

    echo_progress_start "Downloading Komf Jar"
    dlurl="$(curl -sNL https://api.github.com/repos/Snd-R/komf/releases/latest | jq -r '.assets[]?.browser_download_url | select(endswith("jar"))')"
    wget "$dlurl" -O /opt/komf/komf.jar >> "${log}" 2>&1 || {
        echo_error "Download failed"
        exit 1
    }
    chown -R "$user":"$user" /opt/komf
    echo_progress_done "Binary downloaded"
}

config() {
    echo_progress_start "Writting YAML"
        cat > /opt/komf/application.yml <<- SERV
komga:
  baseUri: https://......../komga #or env:KOMF_KOMGA_BASE_URI
  komgaUser: admin #or env:KOMF_KOMGA_USER
  komgaPassword: password #or env:KOMF_KOMGA_PASSWORD
  eventListener:
    enabled: true # if disabled will not connect to komga and won't pick up newly added entries
    libraries: [ ]  # listen to all events if empty
  notifications:
    libraries: [ ]  # Will send notifications if any notification source is enabled. If empty will send notifications for all libraries
  metadataUpdate:
    default:
      libraryType: "MANGA" # Can be "MANGA", "NOVEL" or "COMIC". Hint to help better match book numbers
      updateModes: [ API ] # can use multiple options at once. available options are API, COMIC_INFO
      aggregate: false # if enabled will search and aggregate metadata from all configured providers
      mergeTags: false # if true and aggregate is enabled will merge tags from all providers
      mergeGenres: false # if true and aggregate is enabled will merge genres from all providers
      bookCovers: false # update book thumbnails
      seriesCovers: false # update series thumbnails
      postProcessing:
        seriesTitle: true # update series title
        seriesTitleLanguage: "en" # series title update language. If empty chose first matching title
        alternativeSeriesTitles: false # use other title types as alternative title option
        alternativeSeriesTitleLanguages: # alternative title languages
          - "en"
          - "ja"
          - "ja-ro"
        orderBooks: false # will order books using parsed volume or chapter number
        scoreTag: false # adds score tag of format "score: 8" only uses integer part of rating. Can be used in search using query: tag:"score: 8" in komga
        readingDirectionValue: RIGHT_TO_LEFT # override reading direction for all series. should be one of these: LEFT_TO_RIGHT, RIGHT_TO_LEFT, VERTICAL, WEBTOON
        languageValue: # set default language for series. Must use BCP 47 format e.g. "en"

database:
  file: ./database.sqlite # database file location.

metadataProviders:
  malClientId: 'YOUR KEY HERE' # required for mal provider. See https://myanimelist.net/forum/?topicid=1973077
  defaultProviders:
    mangaUpdates:
      priority: 10
      enabled: true
      mediaType: "MANGA" # filter used in matching. Can be NOVEL or MANGA. MANGA type includes everything except novels
      authorRoles: [ "WRITER" ] # roles that will be mapped to author role
      artistRoles: [ "PENCILLER","INKER","COLORIST","LETTERER","COVER" ] # roles that will be mapped to artist role
    mal:
      priority: 20
      enabled: false
      mediaType: "MANGA" # filter used in matching. Can be NOVEL or MANGA. MANGA type includes everything except novels
    nautiljon:
      priority: 30
      enabled: false
    aniList:
      priority: 40
      enabled: false
      mediaType: "MANGA" # filter used in matching. Can be NOVEL or MANGA. MANGA type includes everything except novels
      tagsScoreThreshold: 60 # tags with this score or higher will be included
      tagsSizeLimit: 15 # amount of tags that will be included
    yenPress:
      priority: 50
      enabled: false
      mediaType: "MANGA" # filter used in matching. Can be NOVEL or MANGA.
    kodansha:
      priority: 60
      enabled: false
    viz:
      priority: 70
      enabled: false
    bookWalker:
      priority: 80
      enabled: false
      mediaType: "MANGA" # filter used in matching. Can be NOVEL or MANGA.
    mangaDex:
      priority: 90
      enabled: false
    bangumi: # Chinese metadata provider. https://bgm.tv/
      priority: 100
      enabled: false

server:
  port: 6801 # or env:KOMF_SERVER_PORT

logLevel: INFO # or env:KOMF_LOG_LEVEL

SERV
echo_progress_done "Komf config installed"
}

systemd() {
    echo_progress_start "Installing systemd service file"
    cat > /etc/systemd/system/komf.service <<- SERV
[Unit]
Description=Komf Service

[Service]
WorkingDirectory=/opt/komf/
ExecStart=/usr/bin/java -jar -Xmx1g /opt/komf/komf.jar --config-dir=/opt/komf/application.yml
User=${user}
Type=simple
Restart=on-failure
RestartSec=10
StandardOutput=null
StandardError=syslog
[Install]
WantedBy=multi-user.target
SERV
    systemctl enable --now komf -q
    echo_progress_done "Komf service installed"
}

nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/komf.sh
        systemctl reload nginx
        echo_progress_done "nginx configured"
    else
        echo_info "Komf will be available on port 6801."
    fi
}

#Install Swizzin Panel Profiles
if [[ -f /install/.panel.lock ]]; then
    cat << EOF >> /opt/swizzin/core/custom/profiles.py
class komf_meta:
    name = "komf"
    pretty_name = "Komf"
    systemd = "komf"
EOF
fi

install
config
systemd

touch /install/.komf.lock
echo_success "Komf installed"