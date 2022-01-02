# enable typed triggers.
# NB this is needed to modify the libvirt domain.
ENV['VAGRANT_EXPERIMENTAL'] = 'typed_triggers'

NUMBER_OF_DISPLAYS = 2

require 'open3'

Vagrant.configure(2) do |config|
  config.vm.box = 'windows-2022-amd64'
  #config.vm.box = 'windows-11-21h2-amd64'

  config.vm.provider 'libvirt' do |lv, config|
    lv.memory = 4*1024
    lv.cpus = 2
    lv.cpu_mode = 'host-passthrough'
    lv.keymap = 'pt'
    lv.nested = true
    lv.disk_bus = 'scsi'
    lv.disk_device = 'sda'
    lv.disk_driver :discard => 'unmap', :cache => 'unsafe'
    (NUMBER_OF_DISPLAYS-1).times do
      lv.qemuargs :value => '-device'
      lv.qemuargs :value => 'qxl'
    end
    config.trigger.before :'VagrantPlugins::ProviderLibvirt::Action::StartDomain', type: :action do |trigger|
      trigger.ruby do |env, machine|
        # modify the scsi controller model to virtio-scsi.
        # see https://github.com/vagrant-libvirt/vagrant-libvirt/pull/692
        # see https://github.com/vagrant-libvirt/vagrant-libvirt/issues/999
        stdout, stderr, status = Open3.capture3(
          'virt-xml', machine.id,
          '--edit', 'type=scsi',
          '--controller', 'model=virtio-scsi')
        if status.exitstatus != 0
          raise "failed to run virt-xml to modify the scsi controller model. status=#{status.exitstatus} stdout=#{stdout} stderr=#{stderr}"
        end
      end
    end
    config.vm.synced_folder '.', '/vagrant',
      type: 'smb',
      smb_username: ENV['VAGRANT_SMB_USERNAME'] || ENV['USER'],
      smb_password: ENV['VAGRANT_SMB_PASSWORD']
  end

  config.vm.provision 'shell', path: 'provision.ps1'
end
