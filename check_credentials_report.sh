#!/bin/bash

# . ./check_iam_compliance_v3.sh i_miyake

operator=$1
accounts=.Accounts.conf
switch_role=SwitchRoleReadOnly
current_time=$(date +%Y%m%d_%H%M)
output_dir=$(pwd)/${current_time}
result_csv=$output_dir/credentials_report_all_${current_time}.csv
result_txt=$output_dir/result_check_iam_all_${current_time}.txt
mkdir -p $output_dir


# 現在との差分日数を返す関数
# (ex) 引数: "2024-01-01T10:10:10+00:00", 戻り値: "320"
get_no_access_days() {
  if [[ "$1" =~ ^[0-9]{4} ]]; then
    current_unixtime=$(date +%s)
    target_unixtime=$(date -d "$1" +%s)

    echo $((($current_unixtime - $target_unixtime) / 86400))
  else
    echo ""
  fi
}


# 各アカウント毎の認証情報レポート取得、規約チェック結果出力を実行
while read -r account  || [ -n "$account" ]; do
  
  report_csv=${output_dir}/tmp_credentials_report_${account}.csv
  target_csv=${output_dir}/tmp_credentials_report_${account}_target.csv
  output_txt=${output_dir}/tmp_result_check_iam_${account}.txt
  
  # 対象アカウントへスイッチロールした際の資格情報を取得
  OUTPUT=$(aws sts assume-role \
          --role-arn arn:aws:iam::${account}:role/${switch_role} \
          --role-session-name $operator)
  
  # 対象アカウント用の資格情報を設定
  export AWS_ACCESS_KEY_ID=$(echo $OUTPUT | jq -r .Credentials.AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo $OUTPUT | jq -r .Credentials.SecretAccessKey)
  export AWS_SESSION_TOKEN=$(echo $OUTPUT | jq -r .Credentials.SessionToken)
  
  add_line() {
  echo "$1" >> $output_txt
  }
  
  # 認証情報レポート取得
  aws iam generate-credential-report; sleep 10
  aws iam get-credential-report --output text --query 'Content' | base64 -d > ${report_csv}
  
  
  # while 文で割り当てる変数用にヘッダー情報を抽出（今後カラム構成が変わったときの保険）
  IFS=, read -r -A report_header < $report_csv
  
  # 認証情報レポートからヘッダーとルートアカウント行を除外したファイルを作成（分析用）
  cat $report_csv | tail -n+2 | grep -vi root_account > $target_csv
  
  
  # 規約チェック結果出力
  while IFS=, read -r $(echo $report_header); do
    user_no_access_days=$(get_no_access_period "$password_last_used")
    key1_no_access_days=$(get_no_access_period "$access_key_1_last_used_date")
    key2_no_access_days=$(get_no_access_period "$access_key_2_last_used_date")
    
    if [ "$mfa_active" = "false"        ]; then add_line "${arn}: MFA disabled."; fi
    if [ "$user_no_access_days" -gt 180 ]; then add_line "${arn}: User no access days >= 180"; fi
    if [ "$key1_no_access_days" -gt  90 ]; then add_line "${arn}: Key1 no access days >=  90"; fi
    if [ "$key2_no_access_days" -gt  90 ]; then add_line "${arn}: Key2 no access days >=  90"; fi
  done < $target_csv
  
  # 規約チェックに該当するものがない場合、問題ない旨をファイル出力
  if [ ! -e "$output_txt" ]; then echo "There are no issue."; fi
  
  # 変数内の資格情報をリセット
  unset \
    AWS_ACCESS_KEY_ID \
    AWS_SECRET_ACCESS_KEY \
    AWS_SESSION_TOKEN
  
done < $accounts


# 結果ファイルの統合と一時ファイルの削除
echo $report_header | tr ' ' ',' > $result_csv
cat $output_dir/tmp_credentials_report_*_target.csv >> $result_csv
cat $output_dir/tmp_result_check_iam_*.txt          >  $result_txt
rm $output_dir/tmp_*
