import json
import os

with open("../../serverlogs/requests.log") as f:
    num_requests = 0
    for line in f:
        current_line = line.split(' ')
        num_requests += int(current_line[-1])
        num_requests += int(current_line[-2])
        num_requests += int(current_line[-3])

    print(num_requests)
