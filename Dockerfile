FROM ubuntu:20.04 as buildexamples

RUN apt-get update \
    && apt-get install -y git \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/jovyan \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/jovyan

RUN git init \
    && git remote add origin https://github.com/Gurobi/modeling-examples.git \
    && git fetch \
    && git checkout -t origin/master -f \
    && rm -rf .git

FROM python:3.8

ARG GRB_VERSION=9.5.0

# Create user as explained in: https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html#preparing-your-dockerfile
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

# Note: install notebook as root! Or else it will not run
RUN pip install --no-cache-dir notebook

WORKDIR /home/jovyan

COPY --from=buildexamples /home/jovyan .

# Now we install python libraries as user libraries as they will be run by this user.
# Change /home/jovyan permissions to make the user we created the owner
USER root
RUN chown -R ${NB_UID} ${HOME}
USER ${NB_USER}

# Add .local/bin to path
ENV PATH="/home/jovyan/.local/bin:${PATH}"

RUN python -m pip install \
        matplotlib \
        numpy \
        pandas \
        sklearn \
        folium \
        xlrd==1.2.0 \
    && python -m pip install gurobipy==${GRB_VERSION} \
    && mkdir -p /home/jovyan

ENTRYPOINT ["jupyter", "notebook", "--no-browser", "--allow-root" ]

CMD ["--notebook-dir=/home/jovyan", "--NotebookApp.token=''","--NotebookApp.password=''"]

EXPOSE "8888"
