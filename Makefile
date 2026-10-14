CRON_LINE = * * * * * sleep 23 && $(CURDIR)/antivirus-cron.sh $(CURDIR)/$(TARGET) $(CURDIR)/$(MALICIOUS)

TARGET = test_dir
MALICIOUS = quarantine
INTERVAL = 5

.PHONY: all setup run cron install-cron restore clean

all: run

setup:
	mkdir -p $(TARGET) $(MALICIOUS)
	chmod +x antivirusd.sh restore.sh antivirus-cron.sh

run: setup
	./antivirusd.sh $(TARGET) $(MALICIOUS) $(INTERVAL)

cron: setup
	./antivirus-cron.sh $(TARGET) $(MALICIOUS)

install-cron: setup
	(crontab -l 2>/dev/null; echo "$(CRON_LINE)") | crontab -
	@echo "Successfully installed antivirus cron job!"

restore: setup
	./restore.sh $(TARGET) $(MALICIOUS)

clean:
	rm -f directory-info.last directory-info.new