terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    local = {
      source = "hashicorp/local"
    }
    null = {
      source = "hashicorp/null"
    }
    template = {
      source = "hashicorp/template"
    }
    clis = {
      source  = "cloud-native-toolkit/clis"
    }
  }
}

provider "clis" {
  alias = "clis1"

  bin_dir = ".bin3"
}

data clis_check clis1 {
  provider = clis.clis1

  clis = ["jq", "kubectl", "oc"]
}

resource local_file bin_dir {
  filename = "${path.cwd}/.bin_dir"

  content = data.clis_check.clis1.bin_dir
}
