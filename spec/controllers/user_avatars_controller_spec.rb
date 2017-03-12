require 'rails_helper'

describe UserAvatarsController do

  context 'show_proxy_letter' do
    it 'returns not found if external avatar is set somewhere else' do
      SiteSetting.external_system_avatars_url = "https://somewhere.else.com/avatar.png"
      response = get :show_proxy_letter, version: 'v2', letter: 'a', color: 'aaaaaa', size: 20
      expect(response.status).to eq(404)
    end

    it 'returns an avatar if we are allowing the proxy' do
      response = get :show_proxy_letter, version: 'v2', letter: 'a', color: 'aaaaaa', size: 20
      expect(response.status).to eq(200)
    end
  end

  context 'show' do
    it 'handles non local content correctly' do
      SiteSetting.avatar_sizes = "100|49"
      SiteSetting.enable_s3_uploads = true
      SiteSetting.s3_access_key_id = "XXX"
      SiteSetting.s3_secret_access_key = "XXX"
      SiteSetting.s3_upload_bucket = "test"
      SiteSetting.s3_cdn_url = "http://cdn.com"

      FakeWeb.register_uri(:get, "http://cdn.com/something/else", :body => 'image')

      GlobalSetting.expects(:cdn_url).returns("http://awesome.com/boom")


      upload = Fabricate(:upload, url: "//test.s3.amazonaws.com/something")
      Fabricate(:optimized_image,
                              sha1: SecureRandom.hex << "A"*8,
                              upload: upload,
                              width: 98,
                              height: 98,
                              url: "//test.s3.amazonaws.com/something/else")

      user = Fabricate(:user, uploaded_avatar_id: upload.id)

      get :show, size: 97, username: user.username, version: upload.id, hostname: 'default'

      # 98 is closest which is 49 * 2 for retina
      expect(response).to redirect_to("http://awesome.com/boom/user_avatar/default/#{user.username_lower}/98/#{upload.id}_#{OptimizedImage::VERSION}.png")

      get :show, size: 98, username: user.username, version: upload.id, hostname: 'default'
      expect(response.body).to eq("image")
      expect(response.headers["Cache-Control"]).to eq('max-age=31557600, public, immutable')
    end

    it 'serves image even if size missing and its in local mode' do
      SiteSetting.avatar_sizes = "50"

      upload = Fabricate(:upload)
      user = Fabricate(:user, uploaded_avatar_id: upload.id)

      get :show, size: 51, username: user.username, version: upload.id, hostname: 'default'
      expect(response).to be_success
    end
  end
end
