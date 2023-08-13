
max_hops=$1
destination=$2
extract_name() {
    local response="$1"
    echo "$response" | grep -oP '(From |64 bytes from )\K\S+'

}
extract_ip() {
    local response="$1"
    echo "$response" | grep -oP '([0-9]+\.){3}[0-9]+'|tail -1
}
extract_time() {
    local response="$1"
    echo "$response" | grep -oP 'time=\K[^\s]+' | head -1
}

# Loop through the number of specified hops
for ((i=1; i <= max_hops; i++)); do
    name=""
    ip=""
    times=""
    response=$(ping -c 1 -t $i $destination 2>&1)
    name=$(extract_name "$response")
    ip=$(extract_ip "$response")
    for j in {1..3}; do
        if [ -z "$ip" ]; then 
            break
        fi
        response=$(ping -c 1 -t $((i+1)) $ip 2>&1)
        
        
        if echo "$response" | grep -q "Time to live exceeded" || echo "$response" | grep -q "64 bytes from"; then
            times="$times $(extract_time "$response") ms"
        else
            times="$times *"
        fi
    done

    if [ -z "$ip" ]; then
        echo "$i * * *"
    else
        echo "$i $name ($ip) $times"
    fi
    response=$(ping -c 1 -t $i $destination 2>&1)
    
    if echo "$response" | grep -q "64 bytes from $name"; then
        exit 0
    fi
done

