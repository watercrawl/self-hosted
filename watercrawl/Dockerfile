ARG WATER_CRAWL_BACKEND_IMAGE
FROM ${WATER_CRAWL_BACKEND_IMAGE}

COPY plugin_requirements.txt /var/www/plugin_requirements.txt

# Only install requirements if the file is not empty
RUN if [ -s /var/www/plugin_requirements.txt ]; then \
    pip install -r /var/www/plugin_requirements.txt; \
    fi