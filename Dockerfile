FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND="noninteractive"
ARG TARGETPLATFORM

# To suppress the Wine debug messages
ENV WINEDEBUG=-all

# To suppress Box86's info banner to avoid winetricks to crash
ENV BOX86_NOBANNER=1

# Install additional tools
RUN apt-get update \
 && apt-get install --yes --no-install-recommends wget curl ca-certificates gnupg

# `cabextract` is needed by winetricks to install most libraries
# `xvfb` is needed in wine to spawn display window because some Windows program can't run without it (using `xvfb-run`)
# If you are sure you don't need it, feel free to remove
RUN apt install --yes cabextract xvfb

# Install box86 and box64
COPY install-box.sh /
RUN bash /install-box.sh \
 && rm /install-box.sh

# Install wine, wine64, and winetricks
COPY install-wine.sh /
RUN bash /install-wine.sh \
 && rm /install-wine.sh

# Install box wrapper for wine
COPY wrap-wine.sh /
RUN bash /wrap-wine.sh \
 && rm /wrap-wine.sh

# Clean up
RUN apt-get -y autoremove \
 && apt-get clean autoclean \
 && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists

# Add user and group
RUN groupadd group \
  && useradd -m -g group user \
  && usermod -a -G audio user \
  && usermod -a -G video user \
  && chsh -s /bin/bash user \
  && echo 'User Created'

# Initialise wine
RUN mv /root/wine /home/user/ \
  && chown -R user:group /home/user/ \
  && su user -c 'wine wineboot' \
  \
  # wintricks
  && su user -c 'winetricks -q msls31' \
  && su user -c 'winetricks -q ole32' \
  && su user -c 'winetricks -q riched20' \
  && su user -c 'winetricks -q riched30' \
  && su user -c 'winetricks -q win7' \
  \
  # Clean
  && rm -fr /home/user/{.cache,tmp}/* \
  && rm -fr /tmp/* \
  && echo 'Wine Initialized'

ENTRYPOINT ["bash", "-c"]
CMD ["bash"]
