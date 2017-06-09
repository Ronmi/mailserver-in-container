require ["fileinto", "variables", "envelope", "subaddress"];
if header :contains "X-Spam-Flag" "YES" {
    fileinto "Spam";
    stop;
}

if envelope :matches :detail "to" "*" {
    set :lower :upperfirst "name" "${1}";
    if not string :is "${name}" "" {
	fileinto "${name}";
    }
}
