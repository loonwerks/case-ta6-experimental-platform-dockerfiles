ARG EXTRAS_IMG=case-ta-extras
FROM $EXTRAS_IMG

# Get user UID and username
ARG UID
ARG UNAME

# Crammed a lot in here to make building the image faster
RUN useradd -u ${UID} ${UNAME} \
    && mkdir /home/${UNAME} \
    && echo 'echo "______  ___  ____________  ___    _____   ___   _____ _____ "' >> /home/${UNAME}/.bashrc \
    && echo 'echo "|  _  \/ _ \ | ___ \ ___ \/ _ \  /  __ \ / _ \ /  ___|  ___|"' >> /home/${UNAME}/.bashrc \
    && echo 'echo "| | | / /_\ \| |_/ / |_/ / /_\ \ | /  \// /_\ \\\\\\\\ \`--.| |__  "' >> /home/${UNAME}/.bashrc \
    && echo 'echo "| | | |  _  ||    /|  __/|  _  | | |    |  _  | \`--. \  __| "' >> /home/${UNAME}/.bashrc \
    && echo 'echo "| |/ /| | | || |\ \| |   | | | | | \__/\| | | |/\__/ / |___ "' >> /home/${UNAME}/.bashrc \
    && echo 'echo "|___/ \_| |_/\_| \_\_|   \_| |_/  \____/\_| |_/\____/\____/ "' >> /home/${UNAME}/.bashrc \
    && echo 'echo "                                                            "' >> /home/${UNAME}/.bashrc \
    && echo 'echo "Hello, welcome to the CASE TA-6 experimental platform build environment"' >> /home/${UNAME}/.bashrc \
    && echo 'export PATH=/scripts/repo:$PATH' >> /home/${UNAME}/.bashrc \
    && echo 'cd /host' >> /home/${UNAME}/.bashrc \
    && chown -R ${UNAME}:${UNAME} /home/${UNAME} \
    && chmod -R ug+rw /home/${UNAME} 

VOLUME /home/${UNAME}

