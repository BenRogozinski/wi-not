import os
import json
import csv

log_dir = "logs"
output_dir = "output"

def main():
    written_files = []
    for file in os.listdir(log_dir):
        print(f"Parsing {file}")
        connected = True
        with open(log_dir + "/" + file) as log:
            ping_metadata = json.loads(log.readline())
            for line in log:
                if "DNC" in line:
                    connected = False
                    break
                if "---" in line:
                    break
            if connected:
                packet_loss = log.readline().split("%")[0].split(" ")[-1]
                ping_results = log.readline().split(" ")[3].split("/")
            else:
                packet_loss = "DNC"
                ping_results = ["DNC", "DNC", "DNC", "DNC"]
        
        csv_filename = output_dir + "/" + str(ping_metadata["band"]) + "_" + str(ping_metadata["channel"]) + ".csv"
        
        with open(csv_filename, "a") as output:
            writer = csv.writer(output)
            csv_row = [str(ping_metadata["band"])] + [str(ping_metadata["channel"])] + [str(ping_metadata["distance"])] + ping_results + [packet_loss]
            print(csv_row)
            if csv_filename not in written_files:
                ...
                #writer.writerow(["Band", "Channel", "Distance (ms)", "Min latency (ms)", "Avg latency (ms)", "Max latency (ms)", "Mean deviation latency (ms)", "Packet loss (%)"])
            writer.writerow(csv_row)

        written_files.append(csv_filename)
                

if __name__ == "__main__":
    main()