FROM python:3.8.0

WORKDIR /chepy
COPY requirements.txt /chepy
RUN pip install -r /chepy/requirements.txt \
    && pip install python-magic virtualenv \
    && virtualenv -p python3 /chepy/venv \
    && pip install pytest pytest-cov bandit \
    && pip install scapy markdown pefile pyelftools

COPY . /chepy/
RUN git submodule update --init --recursive
RUN cd /chepy \
    && sed -i '/chepy/d' chepy/chepy_plugins/requirements.txt \
    && pip install -e . \
    && venv/bin/pip3 install . \
    && venv/bin/pip3 install -r chepy/chepy_plugins/requirements.txt
RUN pip install -r /chepy/chepy/chepy_plugins/requirements.txt

RUN cd /chepy/ && pytest --disable-pytest-warnings --cov-report=xml --cov=chepy --cov-config=.coveragerc tests/
RUN sed -i 's/enableplugins = false/enableplugins = true/' /root/.chepy/chepy.conf
RUN cd /chepy/ && pytest --disable-pytest-warnings tests_plugins/

RUN cd /chepy/ && bandit --recursive chepy/ --ignore-nosec --skip B101,B413,B303,B310,B112,B304,B320,B410,B404
RUN /chepy/venv/bin/pip3 uninstall -y pytest pytest-cov bandit \
    && rm -rf /chepy/tests \
    && rm -rf /chepy/build \
    && rm -rf /chepy/dist \
    && rm -rf /chepy/ignore \
    && rm -rf /chepy/docs \
    && rm -rf /chepy/plugins_test


FROM python:3.8.0-slim
COPY --from=0 /chepy /chepy
RUN apt update \
    && apt install exiftool libmagic-dev -y \
    && /chepy/venv/bin/chepy -v \
    && sed -i 's/enableplugins = false/enableplugins = true/' /root/.chepy/chepy.conf
WORKDIR /data
VOLUME ["/data"]

ENTRYPOINT ["/chepy/venv/bin/chepy"]
