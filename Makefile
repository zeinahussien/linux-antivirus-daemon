TARGET = test_dir
MALICIOUS = quarantine
INTERVAL = 5

.PHONY: all setup run restore clean

all: run

setup:
	mkdir -p $(TARGET) $(MALICIOUS)
	chmod +x antivirusd.sh restore.sh antivirus-cron.sh

run: setup
	./antivirusd.sh $(TARGET) $(MALICIOUS) $(INTERVAL)

restore: setup
	./restore.sh $(TARGET) $(MALICIOUS)

clean:
	rm -f directory-info.last directory-info.new