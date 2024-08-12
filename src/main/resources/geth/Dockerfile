FROM ethereum/client-go

# 스크립트를 컨테이너 내로 복사
COPY run.sh /run.sh

# 스크립트에 실행 권한 부여
RUN chmod +x /run.sh

# 스크립트를 ENTRYPOINT로 실행
ENTRYPOINT ["/run.sh"]
