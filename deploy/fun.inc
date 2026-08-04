
yn() {
  read -rp "Continue? (y/N): " ans

  case "${ans,,}" in
      y|yes)
          echo "Proceeding..."
          ;;
      n|no|"")
          echo "Returning..."
          exit # Use 'exit' if this is a standalone script
          ;;
      *)
          echo "Invalid input."
          exit # Or exit 1
          ;;
  esac
}
