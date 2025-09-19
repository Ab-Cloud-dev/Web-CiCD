echo "🔄 Updating package list..."
sudo apt update -y

echo "☕ Installing OpenJDK 17..."
sudo apt install -y fontconfig openjdk-17-jre

echo "📌 Java version:"
java -version

echo "🔑 Adding Jenkins GPG key and repo..."
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "🔄 Updating package list..."
sudo apt-get update -y

echo "🛠 Installing Jenkins..."
sudo apt-get install -y jenkins

echo "🚀 Starting Jenkins..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

echo "🧱 Allowing traffic on port 8080..."
sudo ufw allow 8080/tcp || echo "UFW not active or already allowed"
