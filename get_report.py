import csv
import io

from sts_assume_role import sts_assume_role
from credentials_report import credential_report


sts_arg = {
    'account_id': '<switch_destination_account_id>',
    'role': '<switch_destination_role_name>',
    'region': 'asia-northeast-1',
    'operator': '<operation_user_name>',
    # 'profile': '<profile_name>',
}

output = './output.csv'


if __name__ == '__main__':
    session = sts_assume_role(**sts_arg)
    bytes_report = credential_report(session)
    
    csv_data = bytes_report.decode('utf-8')
    csv_reader = csv.reader(io.StringIO(csv_data))
    
    with open(output, 'w', newline='') as f:
        writer = csv.writer(f)
        for row in csv_reader:
            writer.writerow(row)
