FROM watercrawl/watercrawl:v0.1.1

COPY plugin_requirements.txt /var/www/plugin_requirements.txt

# Only install requirements if the file is not empty
RUN if [ -s /var/www/plugin_requirements.txt ]; then \
    pip install -r /var/www/plugin_requirements.txt; \
    fi