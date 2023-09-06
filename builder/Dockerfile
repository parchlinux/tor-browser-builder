FROM archlinux:latest
RUN pacman -Suy --noconfirm --needed git base-devel github-cli > /dev/null
RUN useradd -m builder
RUN echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder
COPY build.sh /home/builder/build.sh
ENTRYPOINT ["/bin/bash", "/home/builder/build.sh"]
