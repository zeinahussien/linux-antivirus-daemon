TARGET = test_dir
MALICIOUS = quarantine
INTERVAL = 5

setup:
	mkdir -p $(TARGET) $(MALICIOUS)
	chmod +x antivirusd.sh restore.sh

run: setup
	./antivirusd.sh $(TARGET) $(MALICIOUS) $(INTERVAL)

restore:
	./restore.sh $(TARGET) $(MALICIOUS)

clean:
	rm -f directory-info.last directory-info.new