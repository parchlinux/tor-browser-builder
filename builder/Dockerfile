FROM archlinux:latest
RUN pacman -Suyy --noconfirm --noprogressbar --needed git base-devel github-cli
RUN useradd -m builder
RUN echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder
COPY build.sh /home/builder/build.sh
ENTRYPOINT ["/bin/bash", "/home/builder/build.sh"]
